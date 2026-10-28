#!/usr/bin/env python3
"""Self-check for skills/team-memory/run_state.py. Stdlib only, no network."""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HELPER = ROOT / "skills" / "team-memory" / "run_state.py"
failures = []


def check(condition, message):
    if condition:
        print("PASS  " + message)
    else:
        print("FAIL  " + message)
        failures.append(message)


def call(cwd, *args, expect=0):
    proc = subprocess.run(
        [sys.executable, str(HELPER), *args],
        cwd=str(cwd),
        text=True,
        capture_output=True,
    )
    if proc.returncode != expect:
        print("command: %s" % " ".join(args), file=sys.stderr)
        print("exit: %d (expected %d)" % (proc.returncode, expect), file=sys.stderr)
        print(proc.stdout, file=sys.stderr)
        print(proc.stderr, file=sys.stderr)
        raise SystemExit(1)
    return proc


def status(cwd, expect=0):
    proc = call(cwd, "status", "--json", expect=expect)
    return json.loads(proc.stdout)


def task(records, task_id):
    return next(item for item in records["tasks"] if item["task_id"] == task_id)


def main():
    with tempfile.TemporaryDirectory(prefix="run-state-") as tmp:
        project = Path(tmp)

        # Fresh project: no checkpoint, and an existing artifact is not approval.
        proc = call(project, "status")
        check("No run checkpoint" in proc.stdout, "fresh project reports no checkpoint")
        check("not approvals" in proc.stdout, "fresh project says artifacts are not approvals")
        (project / ".team").mkdir()
        (project / ".team" / "07-build.md").write_text("existing output\n", encoding="utf-8")
        proc = call(project, "status")
        check("No run checkpoint" in proc.stdout, "existing artifacts do not create a run")
        check("approval" in proc.stdout.lower(), "existing artifacts are not treated as approval")

        # Start a run and two parallel tasks in the same stage.
        run_id = call(project, "start-run", "--profile", "new", "--stage", "build").stdout.strip()
        check(bool(run_id), "start-run returns a run id")
        check((project / ".team/runs/current").read_text().strip() == run_id, "current points at the run")
        call(project, "start-task", "--run", run_id, "--task", "build-fe", "--stage", "build",
             "--agent", "fe", "--input", ".team/06-architecture.md")
        call(project, "start-task", "--run", run_id, "--task", "build-be", "--stage", "build",
             "--agent", "be", "--input", ".team/06-architecture.md")
        events = list((project / ".team/runs" / run_id / "events").glob("*.json"))
        check(len(events) == 2, "parallel tasks write two distinct event files")
        state = status(project, expect=2)
        check(task(state, "build-fe")["status"] == "running", "fe attempt is running")
        check(task(state, "build-be")["status"] == "running", "be attempt is running")
        check(any("running" in warning for warning in state["warnings"]), "running task is reported as uncertain")

        # A running attempt is not started twice.
        proc = call(project, "start-task", "--run", run_id, "--task", "build-fe", "--stage", "build",
                    "--agent", "fe", expect=4)
        check("still running" in proc.stderr, "duplicate start of a running task is refused")

        # Finish both; no approval yet.
        call(project, "finish-task", "--run", run_id, "--task", "build-fe", "--status", "completed",
             "--artifact", ".team/07-build-fe.md", "--evidence", "tests: 3 pass", "--next", "wait for be")
        call(project, "finish-task", "--run", run_id, "--task", "build-be", "--status", "completed",
             "--artifact", ".team/07-build-be.md", "--evidence", "tests: 4 pass", "--next", "wait for gate")
        state = status(project, expect=2)
        check(task(state, "build-fe")["status"] == "completed", "fe attempt completed")
        check(task(state, "build-be")["status"] == "completed", "be attempt completed")
        check(any("no valid approval" in warning for warning in state["warnings"]),
              "completed stage without approval is reported")

        # A completed task is not rerun.
        proc = call(project, "start-task", "--run", run_id, "--task", "build-fe", "--stage", "build",
                    "--agent", "fe", expect=3)
        check("completed" in proc.stderr, "completed task is not rerun")

        # Approval is tied to the artifact hash.
        (project / ".team/07-build.md").write_text("consolidated\n", encoding="utf-8")
        call(project, "approve", "--run", run_id, "--stage", "build",
             "--artifact", ".team/07-build.md", "--by", "tester")
        state = status(project, expect=0)
        check(state["approvals"][0]["state"] == "valid", "fresh approval is valid")
        check(state["next"] == "advance to the next stage", "clean state suggests the next stage")
        (project / ".team/07-build.md").write_text("changed after approval\n", encoding="utf-8")
        state = status(project, expect=2)
        check(any("stale" in warning for warning in state["warnings"]), "changed artifact invalidates approval")

        # Interruption between start and finish, then an explicit retry.
        call(project, "start-task", "--run", run_id, "--task", "qa-check", "--stage", "qa", "--agent", "qa")
        state = status(project, expect=2)
        check(task(state, "qa-check")["status"] == "running", "unfinished task stays running after a stop")
        call(project, "retry", "--run", run_id, "--task", "qa-check", "--reason", "agent stopped")
        state = status(project, expect=2)
        check(task(state, "qa-check")["attempt"] == 2, "retry starts attempt 2")
        check(task(state, "qa-check")["status"] == "running", "retried attempt is running")
        finished = []
        for path in (project / ".team/runs" / run_id / "events").glob("*task_finished*qa-check*.json"):
            finished.append(json.loads(path.read_text(encoding="utf-8")))
        check(any(item["attempt"] == 1 and item["status"] == "interrupted" for item in finished),
              "interrupted attempt is preserved in history")

        # A failed attempt can be retried and keeps history.
        call(project, "finish-task", "--run", run_id, "--task", "qa-check", "--status", "failed",
             "--evidence", "2 tests fail", "--next", "fix tests")
        call(project, "retry", "--run", run_id, "--task", "qa-check", "--reason", "fix the failing tests")
        state = status(project, expect=2)
        check(task(state, "qa-check")["attempt"] == 3, "failed attempt retries as attempt 3")
        check(task(state, "qa-check")["attempts"] == [1, 2, 3], "attempt history is kept")

        # A completed task cannot be retried.
        call(project, "finish-task", "--run", run_id, "--task", "qa-check", "--status", "completed",
             "--artifact", ".team/08-qa.md", "--evidence", "tests pass")
        proc = call(project, "retry", "--run", run_id, "--task", "qa-check", expect=3)
        check("completed" in proc.stderr, "completed task cannot be retried")

        # Invalid JSON is reported and never trusted as a terminal state.
        bad = project / ".team/runs" / run_id / "events" / "999-bad.json"
        bad.write_text("{not json", encoding="utf-8")
        state = status(project, expect=2)
        check(any("invalid event file" in warning for warning in state["warnings"]),
              "malformed event file is reported")
        check(task(state, "qa-check")["status"] == "completed", "malformed file does not replace valid state")

        # Fallback: without a current pointer, the newest run is still found.
        (project / ".team/runs/current").unlink()
        state = status(project, expect=2)
        check(state["run"]["run_id"] == run_id, "status finds the newest run without current")
        (project / ".team/runs/current").write_text("../outside\n", encoding="utf-8")
        state = status(project, expect=2)
        check(state["run"]["run_id"] == run_id, "an invalid current pointer is ignored")

        # Trust-boundary checks.
        proc = call(project, "start-task", "--run", run_id, "--task", "security-review",
                    "--stage", "security", "--agent", "security", expect=0)
        check("started" in proc.stdout, "security task starts")
        proc = call(project, "finish-task", "--run", run_id, "--task", "security-review",
                    "--status", "failed", "--artifact", "../outside.md", expect=1)
        check("relative path" in proc.stderr or "escape" in proc.stderr, "path traversal is refused")
        proc = call(project, "finish-task", "--run", run_id, "--task", "security-review",
                    "--status", "failed", "--evidence", "api_key=super-secret", expect=1)
        check("secret" in proc.stderr, "secret-looking evidence is refused")
        proc = call(project, "finish-task", "--run", run_id, "--task", "security-review",
                    "--status", "failed", "--evidence", "line one\nline two", expect=1)
        check("single line" in proc.stderr, "multi-line evidence is refused")
        proc = call(project, "approve", "--run", run_id, "--stage", "security",
                    "--artifact", "outside.md", "--by", "tester", expect=1)
        check(".team/" in proc.stderr, "approval outside .team/ is refused")

    if failures:
        print("\nrun-state: FAIL (%d)" % len(failures))
        return 1
    print("\nrun-state: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
