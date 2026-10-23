# OpenCode Team

Fikri araştırmadan lansmana kadar götüren bir yapay zekâ ajan ekibi — [opencode](https://opencode.ai) üzerine kurulu, framework'siz ve ek bağımlılıksız.

<p align="center">
  <em>English: <a href="./README.md">README.md</a></em>
</p>

```mermaid
flowchart LR
  classDef start fill:#0969da,stroke:#0969da,color:#ffffff
  classDef disc fill:#e8f1fb,stroke:#4a9fd8,color:#1f2328
  classDef design fill:#f3edff,stroke:#7c5cff,color:#1f2328
  classDef build fill:#e9f9f1,stroke:#2f9e6e,color:#1f2328
  classDef ship fill:#fff4e5,stroke:#e08a2e,color:#1f2328

  idea([fikir]):::start --> discover

  subgraph discover[Keşif]
    direction TB
    research[araştırma]:::disc --> prd[prd]:::disc --> backlog:::disc
  end
  subgraph design[Tasarım]
    direction TB
    ux[ux]:::design --> brand[marka]:::design --> architecture[mimari]:::design
  end
  subgraph build[Geliştirme]
    direction TB
    buildstage[kod]:::build --> qa[qa]:::build --> security[güvenlik]:::build
  end
  subgraph ship[Yayın]
    direction TB
    docs[doküman]:::ship --> release[sürüm]:::ship --> launch[lansman]:::ship
  end

  discover --> design --> build --> ship

  style discover fill:transparent,stroke:#d0d7de,stroke-width:1px
  style design fill:transparent,stroke:#d0d7de,stroke-width:1px
  style build fill:transparent,stroke:#d0d7de,stroke-width:1px
  style ship fill:transparent,stroke:#d0d7de,stroke-width:1px
```

<sub>Her ok bir kapı: sonraki aşama onayınızdan sonra başlar.</sub>

## Nedir?

OpenCode Team, bir kez kurup **her projede** kullanabileceğiniz bir yazılım evidir. Şunları tanımlar:

- **14 rol ajanı** — analist, pm, po, ux, marka, architect, fe, be, qa, devops, security, marketing, docs ve bunları birbirine bağlayan orkestratör
- **12 aşamalı boru hattı** — `team.yaml` içinde tanımlı, kodda gömülü değil; aşama ekleyip çıkarabilir, sıralamayı değiştirebilirsiniz
- **12 yetenek (skill)** — her aşama için bir yöntem, tamamı `skills/team-*` altında yerel; harici skill klonlanmaz veya gerekmez
- **17 slash komutu** — tek aşamayı doğrudan çalıştırın veya tüm boru hattını sürün

Orkestratör **varsayılan ajandır**. Herhangi bir dizinde `opencode` açın, fikrinizi söyleyin; ekip aşama aşama ilerler ve her kapıda onayınızı bekler.

## Kurulum

OpenCode 1.x gerektirir (1.19.0 ile test edildi). OpenCode 2 ayrı bir gelecek sürümdür; bu depo v1 sürümüdür.

```bash
git clone https://github.com/sametcelikbicak/opencode-team
cd opencode-team
./install.sh
```

OpenCode PATH'te yoksa önce kurun veya kurulum betiğinin resmî OpenCode 1.x kurucusunu çalıştırmasına izin verin:

```bash
./install.sh --install-opencode
```

`--install-opencode`, `curl -fsSL https://opencode.ai/install | bash` komutunu çalıştırır. OpenCode 1 ve 2 birlikte bulunamaz: mevcut bir OpenCode 2 ikilisi değiştirilir. Bu bayrak olmadan kurulum betiği OpenCode'u kurmaz ve mevcut ikilinize dokunmaz.

opencode'u yeniden başlatın. Hepsi bu — kurulum global'dir, her proje dizininde çalışır.

`install.sh` repoyu opencode yapılandırmanıza symlink'ler:

| Yol                                 | Hedef                         |
| ----------------------------------- | ----------------------------- |
| `~/.config/opencode/agents`         | `opencode-team/agents`        |
| `~/.config/opencode/commands`       | `opencode-team/commands`      |
| `~/.config/opencode/skills/team-*`  | `opencode-team/skills/team-*` |
| `~/.config/opencode/team.yaml`      | `opencode-team/team.yaml`     |
| `~/.config/opencode/team/AGENTS.md` | `opencode-team/team/AGENTS.md` |

Repo git'te kalır, yapılandırma dizininde symlink bulunur. Repoda bir dosyayı düzenlediğinizde etkisi anında olur.

Kurulum betiği `opencode.json` dosyasını hiçbir zaman değiştirmez. `default_agent` `orchestrator` olarak ayarlı değilse önerilen snippet'i yazdırır, dosyayı olduğu gibi bırakır.

Kurulumu kontrol etmek veya kaldırmak için:

```bash
./install.sh --check
./install.sh --uninstall
```

`--check`, bir symlink eksikse sıfır dışı kodla çıkar. Eksik `default_agent` ayarı hata değil, öneri olarak gösterilir. `--uninstall` yalnızca bu repoya işaret eden symlink'leri kaldırır.

### Manuel kurulum

Kendiniz bağlamak isterseniz `~/.config/opencode/opencode.json` dosyasına ekleyin:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "orchestrator",
  "instructions": [
    "~/.config/opencode/team/AGENTS.md",
    "~/.config/opencode/team.yaml"
  ]
}
```

ve ajan, komut, skill dosyalarını ilgili dizinlere yerleştirin.

## Kullanım

Herhangi bir projede opencode'u açın ve ne istediğinizi söyleyin:

```bash
cd ~/projeler/yeni-uygulama
opencode
```

```
> Serbest çalışanlar için, vade tarihinden önce ve sonra e-posta hatırlatması gönderen fatura takip uygulaması yapmak istiyorum.
```

Orkestratör `team.yaml`'ı okur, bir profil seçer ve aşamaları sırayla yürütür. Her kapıda üretilen çıktıyı gösterir ve onayınızı bekler.

### Tek aşama çalıştırma

Her rolün bir komutu var. Boru hattını atlayıp doğrudan istediğiniz işe gidin:

| Komut           | Rol          | Ne yapar                                        |
| --------------- | ------------ | ----------------------------------------------- |
| `/research`     | analyst      | Pazar ve rakip araştırması                      |
| `/prd`          | pm           | Ürün gereksinim dokümanı                        |
| `/backlog`      | po           | Epikler ve kullanıcı hikâyeleri                 |
| `/ux`           | ux           | Ekran akışları, durumlar, erişilebilirlik       |
| `/brand`        | brand        | Logo, palet, favicon seti, marka kılavuzu       |
| `/architecture` | architect    | Veri modeli, API sözleşmesi, modül sınırları    |
| `/build`        | orchestrator | Frontend + backend uygulaması                   |
| `/qa`           | qa           | Kabul kriterlerinden test üretimi ve çalıştırma |
| `/security`     | security     | Güvenlik incelemesi                             |
| `/docs`         | docs         | README, API dokümanı, CHANGELOG                 |
| `/release`      | devops       | Sürüm, CHANGELOG, dağıtım, geri alma planı      |
| `/launch`       | marketing    | Konumlandırma, metin, kanallar, metrikler       |

Boru hattı kontrolü:

| Komut           | Ne yapar                                                    |
| --------------- | ----------------------------------------------------------- |
| `/team`         | Boru hattını başlatır veya devam ettirir                    |
| `/team-status`  | Hangi aşamalar bitti, sırada ne var, nerede bekleniyor      |
| `/team-next`    | Sıradaki aşamayı çalıştırır                                 |
| `/team-approve` | Mevcut kapıyı onaylar ve devam eder                         |
| `/role`         | Ekibi ve her rolün hangi aşamada devreye girdiğini listeler |

## Ekip

| Rol            | Ajan dosyası             | Model                               | Yazdığı çıktı              |
| -------------- | ------------------------ | ----------------------------------- | -------------------------- |
| Orkestratör    | `agents/orchestrator.md` | `opencode/deepseek-v4.1-flash-free` | — (işi dağıtır)            |
| Analist        | `agents/analyst.md`      | `opencode/beam-free`                | `.team/01-research.md`     |
| PM             | `agents/pm.md`           | `opencode/beam-free`                | `.team/02-prd.md`          |
| PO             | `agents/po.md`           | `opencode/beam-free`                | `.team/03-backlog.md`      |
| UX Tasarımcısı | `agents/ux.md`           | `opencode/beam-free`                | `.team/04-ux.md`           |
| Marka          | `agents/brand.md`        | `opencode/deepseek-v4.1-flash-free` | `.team/05-brand.md`        |
| Mimar          | `agents/architect.md`    | `opencode/deepseek-v4.1-flash-free` | `.team/06-architecture.md` |
| Frontend       | `agents/fe.md`           | `opencode/deepseek-v4.1-flash-free` | `.team/07-build.md`        |
| Backend        | `agents/be.md`           | `opencode/deepseek-v4.1-flash-free` | `.team/07-build.md`        |
| QA             | `agents/qa.md`           | `opencode/deepseek-v4.1-flash-free` | `.team/08-qa.md`           |
| Güvenlik       | `agents/security.md`     | `opencode/deepseek-v4.1-flash-free` | `.team/09-security.md`     |
| Doküman        | `agents/docs.md`         | `opencode/deepseek-v4.1-flash-free` | `.team/10-docs.md`         |
| DevOps         | `agents/devops.md`       | `opencode/deepseek-v4.1-flash-free` | `.team/11-release.md`      |
| Pazarlama      | `agents/marketing.md`    | `opencode/nemotron-3-ultra-free`    | `.team/12-launch.md`       |

Tüm ajanlar `mode: all` ile tanımlıdır — böylece her birine üç yoldan ulaşabilirsiniz: **Tab / Shift+Tab** ile gezinme, **`@agent-adi`** ile bahsetme, **`/komut`** ile çağırma.

Modeller OpenCode Zen'in ücretsiz katmanındandır. Varsayılanlar benchmark ile seçildi: `deepseek-v4.1-flash-free` test setinde tam çalışan kod üreten tek modeldi (9,5–10,5/10, görüntü desteği var), `beam-free` hızlı ve metin-only, `nemotron-3-ultra-free` en iyi Türkçe metni yazıyor. Ajan dosyasından istediğinizi değiştirebilirsiniz.

## Çıktı konvansiyonu

Her aşama bir markdown artefaktı yazar:

```
.team/
  01-research.md
  02-prd.md
  03-backlog.md
  04-ux.md
  05-brand.md
  06-architecture.md
  07-build.md
  08-qa.md
  09-security.md
  10-docs.md
  11-release.md
  12-launch.md
```

Klasör içinde düz dosyalar. Veritabanı yok, framework yok, git'te difflenebilir ve insan her aşamada devreye girebilir.

## Boru hattını özelleştirme

`team.yaml` kod değil, konfigürasyondur. Değiştirin, boru hattı değişsin — kod değişikliği gerekmez.

```yaml
profiles:
  new: # sıfırdan başlarken
    - research
    - prd
    - backlog
    - ux
    - brand
    - architecture
    - build
    - qa
    - security
    - docs
    - release
    - launch
  change: # mevcut bir ürün üzerinde çalışırken
    - research
    - prd
    - architecture
    - build
    - qa

stages:
  - id: research
    title: Pazar ve kullanıcı araştırması
    agent: analyst
    skill: team-market-research
    gate: true # false = onay bekleme
    output: .team/01-research.md
    brief: >
      Pazar bağlamını, rakipleri, hedef kullanıcıyı ve nişini araştır.
      Kaynakları belirt, tahmin yürütme. Karar tablosu ile bitsin.
```

**Proje özel ayar:** proje köküne bir `team.yaml` koyarsanız global olanın yerine geçer. Aynı ekibi mevcut bir kod tabanında yeni fikirdekinden farklı çalıştırmanın yolu budur.

Aşama eklemek için: `stages` listesine ve profil listesine ekleyin. Onayları atlamak için: `gate: false` yapın.

### Rol ekleme

1. `agents/<rol>.md` oluşturun (frontmatter: `name`, `description`, `mode: all`, `model`, `permission`).
2. `team.yaml` içinde `agent: <rol>` olarak referans verin.
3. Doğrudan giriş noktası isterseniz `commands/<rol>.md` komutu ekleyin.

## Dil

Ekip sizin dilinizi takip eder. Ajan talimatları, kod, kod içi yorumlar ve teknik dokümantasyon İngilizcedir; geri kalan her şey — PRD, araştırma, UX gerekçesi, pazarlama metni — kullandığınız dilde yazılır. Her artefakt için istediğiniz zaman özel dil isteyebilirsiniz.

## Gereksinimler

- [opencode](https://opencode.ai) 1.x (1.19.0 ile test edildi)
- Bir OpenCode Zen hesabı veya opencode'da yapılandırılmış herhangi bir sağlayıcı — varsayılanlar ücretsiz katman modellerini kullanır

## Üçüncü taraf bildirimleri

Ekip yetenekleri yereldir. `team-build`, `team-backlog` ve `team-brand`, MIT lisanslı üst kaynak yeteneklerden uyarlanmıştır; atıf ve lisans metni için [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md) dosyasına bakın.

## Lisans

MIT. Detaylar için [LICENSE](./LICENSE) dosyasına bakın.

## Yasal Uyarı

OpenCode Team, topluluk odaklı bir projedir; OpenCode (opencode.ai) veya anomalyco/opencode tarafından oluşturulmamıştır, bunlarla bir bağlantısı yoktur ve bunlar tarafından desteklenmemektedir. "OpenCode", Anomaly şirketinin ticari markasıdır. Bu proje, temel aracı (agent) çerçevesi olarak OpenCode CLI'ı kullanır.
