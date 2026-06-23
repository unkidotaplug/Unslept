<div align="center">
  <img src="assets/icon.png" width="120" alt="Unslept">
  <h1>Unslept</h1>
  <p><b>Не дай Маку уснуть, пока нейросеть пишет код — даже с закрытой крышкой.</b></p>

  <p>
    <a href="https://github.com/unkidotaplug/Unslept/releases/latest/download/Unslept.dmg"><b>⬇️ Скачать Unslept.dmg</b></a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13+">
    <img src="https://img.shields.io/badge/arch-Apple_Silicon_%7C_Intel-success" alt="arch">
    <img src="https://img.shields.io/badge/deps-none-brightgreen" alt="no deps">
    <img src="https://img.shields.io/badge/version-1.2.1-blueviolet" alt="version">
  </p>
</div>

---

## Что это

В 2026-м долгие задачи у нейросетей — норма: рефакторинг на часы, генерация целого проекта, агенты, которые работают без остановки. Прерывать нельзя, а сидеть рядом с ноутом сутками — тоже. Стоит закрыть крышку MacBook — и macOS усыпляет систему, процесс встаёт.

**Unslept** живёт в строке меню и не даёт Маку заснуть — **даже когда крышка закрыта**. Включил, ушёл по делам, нейронка спокойно дорабатывает.

## Возможности

- 🔒 **Не спит с закрытой крышкой** — главное отличие от `caffeinate` и большинства аналогов
- 🌙 **Иконка в строке меню** — замок меняется при включении/выключении
- ⏱ **Auto-off** — Mac сам уснёт через 1 / 2 / 4 / 8 часов
- ⚡ **Автозапуск** при входе в систему
- 🪶 **Без зависимостей** — нативный Swift, ~600 КБ, ничего доставлять не нужно

## Установка

1. **[Скачай Unslept.dmg](https://github.com/unkidotaplug/Unslept/releases/latest/download/Unslept.dmg)** и открой.
2. Перетащи **Unslept** в папку **Applications** (ярлык лежит в том же окне).
3. Первый запуск: **правый клик по Unslept → «Открыть» → «Открыть»**.
   _Приложение без платной подписи Apple, поэтому система переспрашивает — только при первом запуске._

   Если macOS пишет, что приложение «повреждено», выполни в Терминале:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Unslept.app
   ```
4. В строке меню сверху появится иконка замка — это Unslept.

## Использование

| Действие | Что делает |
|---|---|
| **Turn on** | Mac не уснёт, в том числе с закрытой крышкой |
| **Turn off** / **Quit** | Возвращает обычный режим сна |
| **Auto-off** | Автовыключение по таймеру (1–8 часов) |
| **Launch at login** | Запуск Unslept при входе в систему |

> 🔑 При включении и выключении система спросит **пароль администратора**. Это необходимо: без прав админа нельзя изменить системную настройку сна, и закрытая крышка усыпит Mac.

> ⚠️ Выключай через **Turn off** или **Quit**. Если завершить процесс принудительно, Mac не будет засыпать до перезагрузки. Аварийно вернуть сон: `sudo pmset disablesleep 0`.

## Как это работает

Обычные power-assertions (`caffeinate -s`, `IOPMAssertion`) блокируют только *простойный* сон. При закрытии крышки macOS усыпляет Mac **независимо** от них — это отдельный механизм (clamshell sleep). Единственный способ удержать систему с закрытой крышкой без внешнего монитора — системный флаг `pmset disablesleep 1`, который Unslept ставит при включении (с правами админа) и снимает при выключении.

## Сборка из исходников

```bash
git clone https://github.com/unkidotaplug/Unslept.git
cd Unslept
bash build.sh        # компиляция + сборка .app (ad-hoc подпись)
open build/Unslept.app
bash dist.sh         # (опционально) собрать .dmg для раздачи
```

Требования: macOS 13+, Xcode Command Line Tools (Swift 6).

---

<div align="center"><sub>Сделано для вайбкодеров · 2026</sub></div>
