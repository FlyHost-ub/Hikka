# ©️ Dan Gazizullin, 2021-2023
# This file is a part of Hikka Userbot
# 🌐 https://github.com/hikariatama/Hikka
# You can redistribute it and/or modify it under the terms of the GNU AGPLv3
# 🔑 https://www.gnu.org/licenses/agpl-3.0.html

import logging
import os
from random import choice

from .. import loader, translations, utils
from ..inline.types import BotInlineCall

logger = logging.getLogger(__name__)

imgs = [
    "https://i.gifer.com/GmUB.gif",
    "https://i.gifer.com/Afdn.gif",
    "https://i.gifer.com/3uvT.gif",
    "https://i.gifer.com/2qQQ.gif",
    "https://i.gifer.com/Lym6.gif",
    "https://i.gifer.com/IjT4.gif",
    "https://i.gifer.com/A9H.gif",
]


@loader.tds
class QuickstartMod(loader.Module):
    """Notifies user about userbot installation"""

    strings = {
        "name": "Quickstart",
        "base": """🌘🇬🇧 <b>Hello.</b> You've just installed <b>Falcon</b> userbot.

❓ <b>Need help?</b> Feel free to join our support chat. We help <b>everyone</b>.

📼 <b>You can find and install modules using @hikkamods_bot. Simply enter your search query and click ⛩ Install on needed module</b>


💁‍♀️ <b>Quickstart:</b>

1️⃣ <b>Type</b> <code>.help</code> <b>to see modules list</b>
2️⃣ <b>Type</b> <code>.help &lt;ModuleName/command&gt;</code> <b>to see help of module ModuleName</b>
3️⃣ <b>Type</b> <code>.dlmod &lt;link&gt;</code> <b>to load module from link</b>
4️⃣ <b>Type</b> <code>.loadmod</code> <b>with reply to file to install module from it</b>
5️⃣ <b>Type</b> <code>.unloadmod &lt;ModuleName&gt;</code> <b>to unload module ModuleName</b>

💡 <b>Hikka supports modules from Friendly-Telegram, DragonUserbot and GeekTG, as well as its own ones.</b>""",
        "FalconHost": (
            "🤩 <b>Your userbot is installed on FalconHost</b>.If you need help"
            " <b>join our community @FalconHelpChat</b>.  "
            " Every month <b>you will need to go to"
            " @FalconHostBot and renew it</b>."
        ),
        "lavhost": (
            "✌️ <b>Your userbot is installed on lavHost</b>. Make sure to join @lavhost"
            " for important notifications and updates. All questions regarding the"
            " platform should be asked in @lavhostchat."
        ),
        "language_saved": "🇬🇧 Language saved!",
        "language": "🇬🇧 English",
        "btn_support": "🥷 Support chat",
    }

    strings_ru = {
        "base": """🌘🇷🇺 <b>Привет.</b> Твой юзербот <b>Falcon</b> установлен.

❓ <b>Нужна помощь?</b> Вступай в наш чат поддержки. Мы помогаем <b>всем</b>.

📼 <b>Ты можешь искать и устанавливать модули через @hikkamods_bot. Просто введи поисковый запрос и нажми ⛩ Install на нужном модуле</b>


💁‍♀️ <b>Быстрый гайд:</b>

1️⃣ <b>Напиши</b> <code>.help</code> <b>чтобы увидеть список модулей</b>
2️⃣ <b>Напиши</b> <code>.help &lt;Название модуля/команда&gt;</code> <b>чтобы увидеть описание модуля</b>
3️⃣ <b>Напиши</b> <code>.dlmod &lt;ссылка&gt;</code> <b>чтобы загрузить модуль из ссылка</b>
4️⃣ <b>Напиши</b> <code>.loadmod</code> <b>ответом на файл, чтобы загрузить модуль из него</b>
5️⃣ <b>Напиши</b> <code>.unloadmod &lt;Название модуля&gt;</code> <b>чтобы выгрузить модуль</b>

💡 <b>Falcon является форком Hikka и поддерживает модули из Friendly-Telegram, DragonUserbot и GeekTG, а также свои собственные.</b>
""",
        "FalconHost": (
            "🤩 <b>Your userbot is installed on FalconHost</b>.If you need help"
            " <b>join our community @FalconHelpChat</b>.  "
            " Every month <b>you will need to go to"
            " @FalconHostBot and renew it</b>."
        ),
        "lavhost": (
            "✌️ <b>Твой юзербот установлен на lavHost</b>. Вступи в @lavhost, чтобы"
            " получать важные уведомления и обновления. Все вопросы, связанные с"
            " платформой, следует задавать в @lavhostchat."
        ),
        "language_saved": "🇷🇺 Язык сохранен!",
        "language": "🇷🇺 Русский",
        "btn_support": "🥷 Чат поддержки",
    }


    async def client_ready(self):
        if self.get("disable_quickstart"):
            raise loader.SelfUnload

        self.mark = (
            lambda: [
                [
                    {
                        "text": self.strings("btn_support"),
                        "url": "https://t.me/hikka_talks",
                    }
                ],
            ]
            + [
                [
                    {
                        "text": "👩‍⚖️ Privacy Policy",
                        "url": "https://docs.google.com/document/d/15m6-pb1Eya8Zn4y0_7JEdvMLAo_v050rFMaWrjDjvMs/edit?usp=sharing",
                    },
                    {
                        "text": "📜 EULA",
                        "url": "https://docs.google.com/document/d/1sZBk24SWLBLoGxcsZHW8yP7yLncToPGUP1FJ4dS6z5I/edit?usp=sharing",
                    },
                ]
            ]
            + utils.chunks(
                [
                    {
                        "text": (
                            getattr(self, f"strings_{lang}")
                            if lang != "en"
                            else self.strings._base_strings
                        )["language"],
                        "callback": self._change_lang,
                        "args": (lang,),
                    }
                    for lang in [
                        "en",
                        "ru",
                        "fr",
                        "it",
                        "de",
                        "uz",
                        "tr",
                        "es",
                        "kk",
                        "tt",
                    ]
                ],
                3,
            )
        )

        self.text = (
            lambda: self.strings("base")
            + (
                "\n"
                + (
                    self.strings("railway")
                    if "RAILWAY" in os.environ
                    else (self.strings("lavhost") if "LAVHOST" in os.environ else "")
                )
            ).rstrip()
        )

        await self.inline.bot.send_animation(self._client.tg_id, animation=choice(imgs))
        await self.inline.bot.send_message(
            self._client.tg_id,
            self.text(),
            reply_markup=self.inline.generate_markup(self.mark()),
            disable_web_page_preview=True,
        )

        self.set("disable_quickstart", True)

    async def _change_lang(self, call: BotInlineCall, lang: str):
        self._db.set(translations.__name__, "lang", lang)
        await self.allmodules.reload_translations()

        await call.answer(self.strings("language_saved"))
        await call.edit(text=self.text(), reply_markup=self.mark())
