#!/usr/bin/env python3
"""Durable run and task checkpoints for OpenCode Team.

State is a directory of small JSON files under ``.team/runs/``. Event files are
append-only and written atomically (temp file + ``os.replace``), so a reader
never sees a half-written checkpoint. Only the Python standard library is used.

Commands: start-run, start-task, finish-task, retry, approve, status.
Run from the project root. ``status`` is read-only and is the resume entry point.
"""

import argparse
import hashlib
import json
import os
import re
import secrets
import sys
from datetime import datetime, timezone
from pathlib import Path

RUNS = Path(".team/runs")
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,80}$")
SECRET_RE = re.compile(
    r"(?i)(api[_-]?key|password|passwd|secret|access[_-]?token|private[_-]?key)"
    r"\s*[:=]\s*\S+"
)
MAX_TEXT = 500
TASK_EVENTS = ("task_started", "task_finished")


def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def event_stamp():
    # Microseconds keep event filenames ordered without a shared sequence file.
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")


def fail(message, code=1):
    print("run-state: " + message, file=sys.stderr)
    raise SystemExit(code)


def check_id(value, label):
    if not isinstance(value, str) or not ID_RE.match(value):
        fail("%s must match %s, got %r" % (label, ID_RE.pattern, value))
    return value


def normalize_path(value, label, require_team=False):
    path = str(value).replace("\\", "/")
    if not path or path.startswith("/") or re.match(r"^[A-Za-z]:", path):
        fail("%s must be a relative path, got %r" % (label, value))
    if ".." in path.split("/"):
        fail("%s must not escape the project, got %r" % (label, value))
    if require_team and not path.startswith(".team/"):
        fail("%s must be under .team/, got %r" % (label, value))
    return path


def check_text(value, label):
    value = value or ""
    if len(value) > MAX_TEXT:
        fail("%s is longer than %d characters; keep checkpoints short" % (label, MAX_TEXT))
    if "\n" in value or "\r" in value:
        fail("%s must be a single line" % label)
    if SECRET_RE.search(value):
        fail("%s looks like a secret; store only the name and type" % label)
    return value


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(".%s.tmp-%d-%s" % (path.name, os.getpid(), secrets.token_hex(4)))
    tmp.write_text(text, encoding="utf-8")
    os.replace(str(tmp), str(path))


def write_json(path, data):
    atomic_write(path, json.dumps(data, indent=2, sort_keys=True) + "\n")


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def run_dir(run_id):
    check_id(run_id, "run id")
    path = RUNS / run_id
    if not (path / "run.json").is_file():
        fail("run not found: %s" % run_id)
    return path


def resolve_run(run_id):
    if run_id:
        return run_dir(run_id)
    current = RUNS / "current"
    if current.is_file():
        candidate = current.read_text(encoding="utf-8").strip()
        if ID_RE.match(candidate or "") and (RUNS / candidate / "run.json").is_file():
            return RUNS / candidate
    if RUNS.is_dir():
        runs = sorted(RUNS.glob("*/run.json"), key=lambda p: p.stat().st_mtime, reverse=True)
        if runs:
            return runs[0].parent
    return None


def load_events(run):
    events = []
    event_dir = run / "events"
    if not event_dir.is_dir():
        return events
    for path in sorted(event_dir.glob("*.json")):
        data = read_json(path)
        if isinstance(data, dict):
            data["_file"] = path.name
            events.append(data)
        else:
            events.append({"_file": path.name, "_invalid": True})
    return events


def event_name(event, hint, attempt):
    parts = [event_stamp(), event, hint]
    if attempt is not None:
        parts.append("a%d" % attempt)
    parts.append(secrets.token_hex(3))
    return "-".join(parts) + ".json"


def write_event(run, event, hint, attempt=None, **fields):
    data = {"event": event, "at": utc_now(), "run_id": run.name}
    if attempt is not None:
        data["attempt"] = attempt
    data.update(fields)
    write_json(run / "events" / event_name(event, hint, attempt), data)


def task_attempts(events, task_id):
    """Return {attempt: {start, finish, conflicts}} for one task, in file order."""
    attempts = {}
    for event in events:
        if event.get("_invalid") or event.get("task_id") != task_id:
            continue
        kind = event.get("event")
        if kind not in TASK_EVENTS:
            continue
        attempt = event.get("attempt")
        if not isinstance(attempt, int) or attempt < 1:
            continue
        info = attempts.setdefault(attempt, {"start": None, "finish": None, "conflicts": []})
        if kind == "task_started":
            if info["start"] is not None:
                info["conflicts"].append("duplicate task_started")
            else:
                info["start"] = event
        else:
            if info["finish"] is not None:
                info["conflicts"].append("duplicate task_finished")
            else:
                info["finish"] = event
    return attempts


def latest_attempt(attempts):
    return attempts[max(attempts)] if attempts else None


def cmd_start_run(args):
    run_id = check_id(args.run, "run id") if args.run else event_stamp() + "-" + secrets.token_hex(3)
    path = RUNS / run_id
    if (path / "run.json").exists():
        fail("run already exists: %s" % run_id)
    data = {
        "run_id": run_id,
        "created_at": utc_now(),
        "profile": args.profile,
        "stage": args.stage or "",
        "status": "running",
        "session": args.session or "",
        "parent_session": args.parent or "",
    }
    write_json(path / "run.json", data)
    atomic_write(RUNS / "current", run_id + "\n")
    print(run_id)


def cmd_start_task(args):
    run = run_dir(args.run)
    check_id(args.task, "task id")
    check_id(args.stage, "stage")
    check_id(args.agent, "agent")
    inputs = [normalize_path(p, "input") for p in args.input]
    attempts = task_attempts(load_events(run), args.task)
    if attempts:
        number = max(attempts)
        info = attempts[number]
        if info["finish"] is not None:
            status = info["finish"].get("status")
            if status == "completed":
                fail("task %s attempt %d is completed; do not rerun it" % (args.task, number), 3)
            if status in ("failed", "interrupted"):
                fail("task %s attempt %d is %s; use retry" % (args.task, number, status), 4)
            fail("task %s attempt %d is %s; resolve the gate first" % (args.task, number, status), 4)
        fail("task %s attempt %d is still running; reconcile it, then retry" % (args.task, number), 4)
    number = 1
    if args.attempt is not None and args.attempt != number:
        fail("first attempt must be 1, got %d" % args.attempt)
    write_event(
        run,
        "task_started",
        args.task,
        attempt=number,
        task_id=args.task,
        stage=args.stage,
        agent=args.agent,
        status="running",
        session=args.session or "",
        parent_session=args.parent or "",
        inputs=inputs,
        artifacts=[],
        evidence="",
        next="",
    )
    print("%s attempt %d started" % (args.task, number))


def cmd_finish_task(args):
    run = run_dir(args.run)
    check_id(args.task, "task id")
    check_text(args.evidence, "evidence")
    check_text(args.next, "next action")
    artifacts = [normalize_path(p, "artifact") for p in args.artifact]
    attempts = task_attempts(load_events(run), args.task)
    if not attempts:
        fail("task %s has no start event" % args.task)
    number = max(attempts)
    info = attempts[number]
    if info["start"] is None:
        fail("task %s attempt %d has no start event" % (args.task, number))
    if info["finish"] is not None:
        fail("task %s attempt %d already has a terminal event" % (args.task, number), 4)
    start = info["start"]
    write_event(
        run,
        "task_finished",
        args.task,
        attempt=number,
        task_id=args.task,
        stage=start.get("stage", ""),
        agent=start.get("agent", ""),
        status=args.status,
        session=args.session or start.get("session", ""),
        parent_session=start.get("parent_session", ""),
        inputs=start.get("inputs", []),
        artifacts=artifacts,
        evidence=args.evidence or "",
        next=args.next or "",
    )
    print("%s attempt %d %s" % (args.task, number, args.status))


def cmd_retry(args):
    run = run_dir(args.run)
    check_id(args.task, "task id")
    check_text(args.reason, "reason")
    attempts = task_attempts(load_events(run), args.task)
    if not attempts:
        fail("task %s has no start event" % args.task)
    number = max(attempts)
    info = attempts[number]
    if info["start"] is None:
        fail("task %s attempt %d has no start event" % (args.task, number))
    status = info["finish"].get("status") if info["finish"] else "running"
    if status == "completed":
        fail("task %s attempt %d is completed; do not retry" % (args.task, number), 3)
    if status == "awaiting_approval":
        fail("task %s attempt %d is awaiting approval; resolve the gate first" % (args.task, number), 4)
    if info["finish"] is None:
        write_event(
            run,
            "task_finished",
            args.task,
            attempt=number,
            task_id=args.task,
            stage=info["start"].get("stage", ""),
            agent=info["start"].get("agent", ""),
            status="interrupted",
            session=info["start"].get("session", ""),
            parent_session=info["start"].get("parent_session", ""),
            inputs=info["start"].get("inputs", []),
            artifacts=[],
            evidence=args.reason or "interrupted before retry",
            next="retry",
        )
    start = info["start"]
    write_event(
        run,
        "task_started",
        args.task,
        attempt=number + 1,
        task_id=args.task,
        stage=start.get("stage", ""),
        agent=start.get("agent", ""),
        status="running",
        session=start.get("session", ""),
        parent_session=start.get("parent_session", ""),
        inputs=start.get("inputs", []),
        artifacts=[],
        evidence="",
        next="",
    )
    print("%s attempt %d started" % (args.task, number + 1))


def cmd_approve(args):
    run = run_dir(args.run)
    check_id(args.stage, "stage")
    artifact = normalize_path(args.artifact, "artifact", require_team=True)
    check_text(args.note, "note")
    if not args.by.strip():
        fail("approver name is required")
    path = Path(artifact)
    if not path.is_file():
        fail("artifact not found: %s" % artifact)
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    data = {
        "stage": args.stage,
        "artifact": artifact,
        "sha256": digest,
        "by": args.by.strip(),
        "approved_at": utc_now(),
        "note": args.note or "",
    }
    name = "%s-%s-%s.json" % (event_stamp(), args.stage, secrets.token_hex(3))
    write_json(run / "approvals" / name, data)
    print("approved %s: %s" % (args.stage, artifact))


def load_approvals(run):
    records = []
    directory = run / "approvals"
    if not directory.is_dir():
        return records
    for path in sorted(directory.glob("*.json")):
        data = read_json(path)
        if not isinstance(data, dict):
            records.append({"_file": path.name, "_invalid": True})
            continue
        data["_file"] = path.name
        records.append(data)
    return records


def task_summary(events, task_id):
    attempts = task_attempts(events, task_id)
    if not attempts:
        return None
    number = max(attempts)
    info = attempts[number]
    start = info["start"] or {}
    finish = info["finish"] or {}
    status = finish.get("status", "running" if start else "unknown")
    return {
        "task_id": task_id,
        "attempt": number,
        "status": status,
        "stage": start.get("stage", ""),
        "agent": start.get("agent", ""),
        "artifacts": finish.get("artifacts", []),
        "next": finish.get("next", ""),
        "conflicts": info["conflicts"],
        "attempts": sorted(attempts),
    }


def build_status(run):
    run_data = read_json(run / "run.json")
    warnings = []
    if not isinstance(run_data, dict):
        return None, ["invalid run.json; do not trust this checkpoint"]
    events = load_events(run)
    for event in events:
        if event.get("_invalid"):
            warnings.append("invalid event file %s; ignored" % event["_file"])
    task_ids = []
    for event in events:
        if event.get("_invalid"):
            continue
        task_id = event.get("task_id")
        if event.get("event") in TASK_EVENTS and isinstance(task_id, str) and task_id not in task_ids:
            task_ids.append(task_id)
    tasks = []
    for task_id in sorted(task_ids):
        summary = task_summary(events, task_id)
        if summary is None:
            continue
        tasks.append(summary)
        if summary["conflicts"]:
            warnings.append("task %s has conflicting checkpoint events: %s" % (task_id, ", ".join(summary["conflicts"])))
        if summary["status"] == "running":
            warnings.append("task %s attempt %d is running; reconcile it against artifacts before retrying" % (task_id, summary["attempt"]))
        elif summary["status"] in ("failed", "interrupted"):
            warnings.append("task %s attempt %d is %s; retry explicitly" % (task_id, summary["attempt"], summary["status"]))
        elif summary["status"] == "awaiting_approval":
            warnings.append("task %s attempt %d is awaiting human approval" % (task_id, summary["attempt"]))

    approvals = {}
    for record in load_approvals(run):
        if record.get("_invalid"):
            warnings.append("invalid approval file %s; ignored" % record["_file"])
            continue
        stage = record.get("stage")
        artifact = record.get("artifact")
        digest = record.get("sha256")
        if not isinstance(stage, str) or not isinstance(artifact, str) or not isinstance(digest, str):
            warnings.append("approval %s is missing stage, artifact or sha256; ignored" % record["_file"])
            continue
        path = Path(artifact)
        if not path.is_file():
            state = "stale (artifact missing)"
        else:
            state = "valid" if hashlib.sha256(path.read_bytes()).hexdigest() == digest else "stale (artifact changed)"
        entry = dict(record)
        entry["state"] = state
        current = approvals.get(stage)
        if current is None or (entry.get("approved_at", ""), record["_file"]) >= (current.get("approved_at", ""), current["_file"]):
            approvals[stage] = entry
        if state != "valid":
            warnings.append("approval for stage %s is %s" % (stage, state))

    for task in tasks:
        if task["status"] != "completed":
            continue
        stage = task["stage"]
        if stage and (stage not in approvals or approvals[stage]["state"] != "valid"):
            warnings.append("task %s completed but stage %s has no valid approval" % (task["task_id"], stage))

    latest_stage = run_data.get("stage", "")
    for event in events:
        if event.get("_invalid"):
            continue
        if event.get("stage"):
            latest_stage = event["stage"]

    if warnings:
        next_action = "resolve the warnings before dispatching or advancing"
    elif not tasks:
        next_action = "start the first task"
    elif any(task["status"] in ("running", "failed", "interrupted") for task in tasks):
        next_action = "reconcile or retry unfinished tasks"
    elif any(task["status"] == "completed" for task in tasks):
        next_action = "advance to the next stage"
    else:
        next_action = "check the run state"

    result = {
        "run": run_data,
        "stage": latest_stage,
        "tasks": tasks,
        "approvals": list(approvals.values()),
        "warnings": warnings,
        "next": next_action,
    }
    return result, warnings


def print_status(result):
    run = result["run"]
    print("run: %s (profile=%s, stage=%s, created=%s)" % (
        run.get("run_id", "?"), run.get("profile", "?"), result["stage"] or "-", run.get("created_at", "?")
    ))
    if result["tasks"]:
        print("tasks:")
        for task in result["tasks"]:
            print("  %s attempt %d: %s (agent=%s, stage=%s)" % (
                task["task_id"], task["attempt"], task["status"], task["agent"] or "-", task["stage"] or "-"
            ))
            if task["artifacts"]:
                print("    artifacts: %s" % ", ".join(task["artifacts"]))
            if task["next"]:
                print("    next: %s" % task["next"])
    else:
        print("tasks: none")
    if result["approvals"]:
        print("approvals:")
        for approval in result["approvals"]:
            print("  %s: %s (by %s, %s; %s)" % (
                approval.get("stage", "?"), approval.get("state", "?"),
                approval.get("by", "?"), approval.get("approved_at", "?"), approval.get("artifact", "?")
            ))
    else:
        print("approvals: none")
    if result["warnings"]:
        print("warnings:")
        for warning in result["warnings"]:
            print("  - %s" % warning)
    print("next: %s" % result["next"])


def cmd_status(args):
    run = resolve_run(args.run)
    if run is None:
        print("No run checkpoint in .team/runs/.")
        print("Initialize one with: run_state.py start-run --profile <new|change>")
        print("Existing artifacts are not approvals; review the artifact before advancing.")
        return 0
    result, warnings = build_status(run)
    if result is None:
        for warning in warnings:
            print("  - %s" % warning, file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print_status(result)
    return 2 if warnings else 0


def build_parser():
    parser = argparse.ArgumentParser(description="Durable run and task checkpoints for OpenCode Team.")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("start-run", help="create a run checkpoint")
    p.add_argument("--run")
    p.add_argument("--profile", default="new")
    p.add_argument("--stage", default="")
    p.add_argument("--session", default="")
    p.add_argument("--parent", default="")
    p.set_defaults(func=cmd_start_run)

    p = sub.add_parser("start-task", help="record a task before dispatch")
    p.add_argument("--run", required=True)
    p.add_argument("--task", required=True)
    p.add_argument("--stage", required=True)
    p.add_argument("--agent", required=True)
    p.add_argument("--input", action="append", default=[])
    p.add_argument("--session", default="")
    p.add_argument("--parent", default="")
    p.add_argument("--attempt", type=int)
    p.set_defaults(func=cmd_start_task)

    p = sub.add_parser("finish-task", help="record a terminal task outcome")
    p.add_argument("--run", required=True)
    p.add_argument("--task", required=True)
    p.add_argument("--status", required=True, choices=["completed", "failed", "interrupted", "awaiting_approval"])
    p.add_argument("--artifact", action="append", default=[])
    p.add_argument("--evidence", default="")
    p.add_argument("--next", default="")
    p.add_argument("--session", default="")
    p.set_defaults(func=cmd_finish_task)

    p = sub.add_parser("retry", help="start the next attempt after an interruption or failure")
    p.add_argument("--run", required=True)
    p.add_argument("--task", required=True)
    p.add_argument("--reason", default="")
    p.set_defaults(func=cmd_retry)

    p = sub.add_parser("approve", help="record human approval tied to an artifact hash")
    p.add_argument("--run", required=True)
    p.add_argument("--stage", required=True)
    p.add_argument("--artifact", required=True)
    p.add_argument("--by", required=True)
    p.add_argument("--note", default="")
    p.set_defaults(func=cmd_approve)

    p = sub.add_parser("status", help="read and validate checkpoints (resume entry point)")
    p.add_argument("--run")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_status)
    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
