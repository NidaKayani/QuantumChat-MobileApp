import 'package:flutter/material.dart';

import '../theme/qc_theme.dart';

/// Emoji category definition matching the web's `EMOJI_CATEGORIES`.
class _EmojiCategory {
  const _EmojiCategory({required this.id, required this.label, required this.icon, required this.emojis});
  final String id;
  final String label;
  final IconData icon;
  final List<String> emojis;
}

const _categories = <_EmojiCategory>[
  _EmojiCategory(
    id: 'recent',
    label: 'Recently Used',
    icon: Icons.access_time,
    emojis: [], // filled at runtime
  ),
  _EmojiCategory(
    id: 'smileys',
    label: 'Smileys & People',
    icon: Icons.emoji_emotions_outlined,
    emojis: [
      '😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃',
      '😉','😊','😇','🥰','😍','🤩','😘','😗','☺️','😚',
      '😙','🥲','😋','😛','😜','🤪','😝','🤑','🤗','🤭',
      '🤫','🤔','🤐','🤨','😐','😑','😶','😏','😒','🙄',
      '😬','😮‍💨','🤥','😌','😔','😪','🤤','😴','😷','🤒',
      '🤕','🤢','🤮','🤧','🥵','🥶','🥴','😵','🤯','🤠',
      '🥳','🥸','😎','🤓','🧐','😕','😟','🙁','☹️','😮',
      '😯','😲','😳','🥺','😦','😧','😨','😰','😥','😢',
      '😭','😱','😖','😣','😞','😓','😩','😫','🥱','😤',
      '😡','😠','🤬','😈','👿','💀','☠️','💩','🤡','👹',
      '👺','👻','👽','👾','🤖','😺','😸','😹','😻','😼',
      '😽','🙀','😿','😾','🙈','🙉','🙊','💋','💌','💘',
      '💝','💖','💗','💓','💞','💕','💟','❣️','💔','❤️',
      '🧡','💛','💚','💙','💜','🤎','🖤','🤍','💯','💢',
      '💥','💫','💦','💨','🕳️','💬','👁️‍🗨️','🗨️','🗯️','💭',
      '👋','🤚','🖐️','✋','🖖','👌','🤌','🤏','✌️','🤞',
      '🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','👍',
      '👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝',
      '🙏','✍️','💅','🤳','💪','🦾','🦿','🦵','🦶','👂',
      '🦻','👃','🧠','🫀','🫁','🦷','🦴','👀','👁️','👅',
      '👄','👶','🧒','👦','👧','🧑','👱','👨','🧔','👩',
      '🧓','👴','👵','🙍','🙎','🙅','🙆','💁','🙋','🧏',
      '🙇','🤦','🤷','👮','🕵️','💂','🥷','👷','🤴','👸',
      '👳','👲','🧕','🤵','👰','🤰','🤱','👼','🎅','🤶',
      '🦸','🦹','🧙','🧚','🧛','🧜','🧝','🧞','🧟','💆',
      '💇','🚶','🧍','🧎','🏃','💃','🕺','🕴️','👯','🧘',
      '🛀','🛌','🧑‍🤝‍🧑','👭','👫','👬','💏','💑','👪','🗣️',
      '👤','👥','🫂','👣',
    ],
  ),
  _EmojiCategory(
    id: 'animals',
    label: 'Animals & Nature',
    icon: Icons.pets_outlined,
    emojis: [
      '🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐻‍❄️','🐨',
      '🐯','🦁','🐮','🐷','🐽','🐸','🐵','🙈','🙉','🙊',
      '🐒','🐔','🐧','🐦','🐤','🐣','🐥','🦆','🦅','🦉',
      '🦇','🐺','🐗','🐴','🦄','🐝','🪱','🐛','🦋','🐌',
      '🐞','🐜','🪰','🪲','🪳','🦟','🦗','🕷️','🕸️','🦂',
      '🐢','🐍','🦎','🦖','🦕','🐙','🦑','🦐','🦞','🦀',
      '🐡','🐠','🐟','🐬','🐳','🐋','🦈','🐊','🐅','🐆',
      '🦓','🦍','🦧','🦣','🐘','🦛','🦏','🐪','🐫','🦒',
      '🦘','🦬','🐃','🐂','🐄','🐎','🐖','🐏','🐑','🦙',
      '🐐','🦌','🐕','🐩','🦮','🐕‍🦺','🐈','🐈‍⬛','🪶','🐓',
      '🦃','🦤','🦚','🦜','🦢','🦩','🕊️','🐇','🦝','🦨',
      '🦡','🦫','🦦','🦥','🐁','🐀','🐿️','🦔','🐾','🐉',
      '🐲','🌵','🎄','🌲','🌳','🌴','🪵','🌱','🌿','☘️',
      '🍀','🎍','🪴','🎋','🍃','🍂','🍁','🍄','🐚','🪨',
      '🌾','💐','🌷','🌹','🥀','🌺','🌸','🌼','🌻','🌞',
      '🌝','🌛','🌜','🌚','🌕','🌖','🌗','🌘','🌑','🌒',
      '🌓','🌔','🌙','🌎','🌍','🌏','🪐','💫','⭐','🌟',
      '✨','⚡','☄️','💥','🔥','🌪️','🌈','☀️','🌤️','⛅',
      '🌥️','☁️','🌦️','🌧️','⛈️','🌩️','🌨️','❄️','☃️','⛄',
      '🌬️','💨','💧','💦','☔','☂️','🌊','🌫️',
    ],
  ),
  _EmojiCategory(
    id: 'food',
    label: 'Food & Drink',
    icon: Icons.fastfood_outlined,
    emojis: [
      '🍇','🍈','🍉','🍊','🍋','🍌','🍍','🥭','🍎','🍏',
      '🍐','🍑','🍒','🍓','🫐','🥝','🍅','🫒','🥥','🥑',
      '🍆','🥔','🥕','🌽','🌶️','🫑','🥒','🥬','🥦','🧄',
      '🧅','🍄','🥜','🌰','🍞','🥐','🥖','🫓','🥨','🥯',
      '🥞','🧇','🧀','🍖','🍗','🥩','🥓','🍔','🍟','🍕',
      '🌭','🥪','🌮','🌯','🫔','🥙','🧆','🥚','🍳','🥘',
      '🍲','🫕','🥣','🥗','🍿','🧈','🧂','🥫','🍱','🍘',
      '🍙','🍚','🍛','🍜','🍝','🍠','🍢','🍣','🍤','🍥',
      '🥮','🍡','🥟','🥠','🥡','🦀','🦞','🦐','🦑','🦪',
      '🍦','🍧','🍨','🍩','🍪','🎂','🍰','🧁','🥧','🍫',
      '🍬','🍭','🍮','🍯','🍼','🥛','☕','🫖','🍵','🍶',
      '🍾','🍷','🍸','🍹','🍺','🍻','🥂','🥃','🥤','🧋',
      '🧃','🧉','🧊','🥢','🍽️','🍴','🥄','🔪','🏺',
    ],
  ),
  _EmojiCategory(
    id: 'activity',
    label: 'Activities',
    icon: Icons.sports_soccer_outlined,
    emojis: [
      '⚽','🏀','🏈','⚾','🥎','🎾','🏐','🏉','🥏','🎱',
      '🪀','🏓','🏸','🏒','🏑','🥍','🏏','🪃','🥅','⛳',
      '🪁','🏹','🎣','🤿','🥊','🥋','🎽','🛹','🛼','🛷',
      '⛸️','🥌','🎿','⛷️','🏂','🪂','🏋️','🤼','🤸','⛹️',
      '🤺','🤾','🏌️','🏇','🧘','🏄','🏊','🤽','🚣','🧗',
      '🚵','🚴','🏆','🥇','🥈','🥉','🏅','🎖️','🏵️','🎗️',
      '🎫','🎟️','🎪','🤹','🎭','🩰','🎨','🎬','🎤','🎧',
      '🎼','🎹','🥁','🪘','🎷','🎺','🪗','🎸','🪕','🎻',
      '🎲','♟️','🎯','🎳','🎮','🎰','🧩',
    ],
  ),
  _EmojiCategory(
    id: 'travel',
    label: 'Travel & Places',
    icon: Icons.flight_outlined,
    emojis: [
      '🚗','🚕','🚙','🚌','🚎','🏎️','🚓','🚑','🚒','🚐',
      '🛻','🚚','🚛','🚜','🦯','🦽','🦼','🛴','🚲','🛵',
      '🏍️','🛺','🚨','🚔','🚍','🚘','🚖','🚡','🚠','🚟',
      '🚃','🚋','🚞','🚝','🚄','🚅','🚈','🚂','🚆','🚇',
      '🚊','🚉','✈️','🛫','🛬','🛩️','💺','🛰️','🚀','🛸',
      '🚁','🛶','⛵','🚤','🛥️','🛳️','⛴️','🚢','⚓','🪝',
      '⛽','🚧','🚦','🚥','🚏','🗺️','🗿','🗽','🗼','🏰',
      '🏯','🏟️','🎡','🎢','🎠','⛲','⛱️','🏖️','🏝️','🏜️',
      '🌋','⛰️','🏔️','🗻','🏕️','⛺','🏠','🏡','🏘️','🏚️',
      '🏗️','🏭','🏢','🏬','🏣','🏤','🏥','🏦','🏨','🏪',
      '🏫','🏩','💒','🏛️','⛪','🕌','🕍','🛕','🕋','⛩️',
      '🛤️','🛣️','🗾','🎑','🏞️','🌅','🌄','🌠','🎇','🎆',
      '🌇','🌆','🏙️','🌃','🌌','🌉','🌁',
    ],
  ),
  _EmojiCategory(
    id: 'objects',
    label: 'Objects',
    icon: Icons.lightbulb_outlined,
    emojis: [
      '⌚','📱','📲','💻','⌨️','🖥️','🖨️','🖱️','🖲️','🕹️',
      '🗜️','💽','💾','💿','📀','📼','📷','📸','📹','🎥',
      '📽️','🎞️','📞','☎️','📟','📠','📺','📻','🎙️','🎚️',
      '🎛️','🧭','⏱️','⏲️','⏰','🕰️','⌛','⏳','📡','🔋',
      '🔌','💡','🔦','🕯️','🪔','🧯','🛢️','💸','💵','💴',
      '💶','💷','🪙','💰','💳','💎','⚖️','🪜','🧰','🪛',
      '🔧','🔨','⚒️','🛠️','⛏️','🪚','🔩','⚙️','🪤','🧱',
      '⛓️','🧲','🔫','💣','🧨','🪓','🔪','🗡️','⚔️','🛡️',
      '🚬','⚰️','🪦','⚱️','🏺','🔮','📿','🧿','💈','⚗️',
      '🔭','🔬','🕳️','🩹','🩺','💊','💉','🩸','🧬','🦠',
      '🧫','🧪','🌡️','🧹','🪠','🧺','🧻','🚽','🚰','🚿',
      '🛁','🛀','🧼','🪥','🪒','🧽','🪣','🧴','🛎️','🔑',
      '🗝️','🚪','🪑','🛋️','🛏️','🛌','🧸','🖼️','🪞','🪟',
      '🛍️','🛒','🎁','🎈','🎏','🎀','🪄','🪅','🎊','🎉',
      '🎎','🏮','🎐','🧧','✉️','📩','📨','📧','💌','📥',
      '📤','📦','🏷️','🪧','📪','📫','📬','📭','📮','📯',
      '📜','📃','📄','📑','🧾','📊','📈','📉','🗒️','🗓️',
      '📆','📅','🗑️','📇','🗃️','🗳️','🗄️','📋','📁','📂',
      '🗂️','🗞️','📰','📓','📔','📒','📕','📗','📘','📙',
      '📚','📖','🔖','🧷','🔗','📎','🖇️','📐','📏','🧮',
      '📌','📍','✂️','🖊️','🖋️','✒️','🖌️','🖍️','📝','✏️',
      '🔍','🔎','🔏','🔐','🔒','🔓',
    ],
  ),
  _EmojiCategory(
    id: 'symbols',
    label: 'Symbols',
    icon: Icons.emoji_symbols_outlined,
    emojis: [
      '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔',
      '❣️','💕','💞','💓','💗','💖','💘','💝','💟','☮️',
      '✝️','☪️','🕉️','☸️','✡️','🔯','🕎','☯️','☦️','🛐',
      '⛎','♈','♉','♊','♋','♌','♍','♎','♏','♐',
      '♑','♒','♓','🆔','⚛️','🉑','☢️','☣️','📴','📳',
      '🈶','🈚','🈸','🈺','🈷️','✴️','🆚','💮','🉐','㊙️',
      '㊗️','🈴','🈵','🈹','🈲','🅰️','🅱️','🆎','🆑','🅾️',
      '🆘','❌','⭕','🛑','⛔','📛','🚫','💯','💢','♨️',
      '🚷','🚯','🚳','🚱','🔞','📵','🚭','❗','❕','❓',
      '❔','‼️','⁉️','🔅','🔆','〽️','⚠️','🚸','🔱','⚜️',
      '🔰','♻️','✅','🈯','💹','❇️','✳️','❎','🌐','💠',
      'Ⓜ️','🌀','💤','🏧','🚾','♿','🅿️','🛗','🈳','🈂️',
      '🛂','🛃','🛄','🛅','♂️','♀️','⚧️','✖️','➕','➖',
      '➗','♾️','‼️','⁉️','❓','❔','❕','❗','〰️','💱',
      '💲','⚕️','♻️','⚜️','🔱','📛','🔰','⭕','✅','☑️',
      '✔️','❌','❎','➰','➿','〽️','✳️','✴️','❇️','©️',
      '®️','™️','#️⃣','*️⃣','0️⃣','1️⃣','2️⃣','3️⃣','4️⃣','5️⃣',
      '6️⃣','7️⃣','8️⃣','9️⃣','🔟','🔠','🔡','🔢','🔣','🔤',
      '🅰️','🆎','🅱️','🆑','🆒','🆓','ℹ️','🆔','Ⓜ️','🆕',
      '🆖','🅾️','🆗','🅿️','🆘','🆙','🆚','🈁','🈂️','🈷️',
      '🈶','🈯','🉐','🈹','🈚','🈲','🉑','🈸','🈴','🈳',
      '㊗️','㊙️','🈺','🈵','🔴','🟠','🟡','🟢','🔵','🟣',
      '🟤','⚫','⚪','🟥','🟧','🟨','🟩','🟦','🟪','🟫',
      '⬛','⬜','◼️','◻️','◾','◽','▪️','▫️','🔶','🔷',
      '🔸','🔹','🔺','🔻','💠','🔘','🔳','🔲',
    ],
  ),
  _EmojiCategory(
    id: 'flags',
    label: 'Flags',
    icon: Icons.flag_outlined,
    emojis: [
      '🏁','🚩','🎌','🏴','🏳️','🏳️‍🌈','🏳️‍⚧️','🏴‍☠️',
      '🇦🇫','🇦🇽','🇦🇱','🇩🇿','🇦🇸','🇦🇩','🇦🇴','🇦🇮','🇦🇶','🇦🇬',
      '🇦🇷','🇦🇲','🇦🇼','🇦🇺','🇦🇹','🇦🇿','🇧🇸','🇧🇭','🇧🇩','🇧🇧',
      '🇧🇾','🇧🇪','🇧🇿','🇧🇯','🇧🇲','🇧🇹','🇧🇴','🇧🇦','🇧🇼','🇧🇷',
      '🇮🇴','🇻🇬','🇧🇳','🇧🇬','🇧🇫','🇧🇮','🇰🇭','🇨🇲','🇨🇦','🇮🇨',
      '🇨🇻','🇧🇶','🇰🇾','🇨🇫','🇹🇩','🇨🇱','🇨🇳','🇨🇽','🇨🇨','🇨🇴',
      '🇰🇲','🇨🇬','🇨🇩','🇨🇰','🇨🇷','🇨🇮','🇭🇷','🇨🇺','🇨🇼','🇨🇾',
      '🇨🇿','🇩🇰','🇩🇯','🇩🇲','🇩🇴','🇪🇨','🇪🇬','🇸🇻','🇬🇶','🇪🇷',
      '🇪🇪','🇸🇿','🇪🇹','🇪🇺','🇫🇰','🇫🇴','🇫🇯','🇫🇮','🇫🇷','🇬🇫',
      '🇵🇫','🇹🇫','🇬🇦','🇬🇲','🇬🇪','🇩🇪','🇬🇭','🇬🇮','🇬🇷','🇬🇱',
      '🇬🇩','🇬🇵','🇬🇺','🇬🇹','🇬🇬','🇬🇳','🇬🇼','🇬🇾','🇭🇹','🇭🇳',
      '🇭🇰','🇭🇺','🇮🇸','🇮🇳','🇮🇩','🇮🇷','🇮🇶','🇮🇪','🇮🇲','🇮🇱',
      '🇮🇹','🇯🇲','🇯🇵','🇯🇪','🇯🇴','🇰🇿','🇰🇪','🇰🇮','🇽🇰','🇰🇼',
      '🇰🇬','🇱🇦','🇱🇻','🇱🇧','🇱🇸','🇱🇷','🇱🇾','🇱🇮','🇱🇹','🇱🇺',
      '🇲🇴','🇲🇬','🇲🇼','🇲🇾','🇲🇻','🇲🇱','🇲🇹','🇲🇭','🇲🇶','🇲🇷',
      '🇲🇺','🇾🇹','🇲🇽','🇫🇲','🇲🇩','🇲🇨','🇲🇳','🇲🇪','🇲🇸','🇲🇦',
      '🇲🇿','🇲🇲','🇳🇦','🇳🇷','🇳🇵','🇳🇱','🇳🇨','🇳🇿','🇳🇮','🇳🇪',
      '🇳🇬','🇳🇺','🇳🇫','🇰🇵','🇲🇰','🇲🇵','🇳🇴','🇴🇲','🇵🇰','🇵🇼',
      '🇵🇸','🇵🇦','🇵🇬','🇵🇾','🇵🇪','🇵🇭','🇵🇳','🇵🇱','🇵🇹','🇵🇷',
      '🇶🇦','🇷🇪','🇷🇴','🇷🇺','🇷🇼','🇼🇸','🇸🇲','🇸🇹','🇸🇦','🇸🇳',
      '🇷🇸','🇸🇨','🇸🇱','🇸🇬','🇸🇽','🇸🇰','🇸🇮','🇬🇸','🇸🇧','🇸🇴',
      '🇿🇦','🇰🇷','🇸🇸','🇪🇸','🇱🇰','🇧🇱','🇸🇭','🇰🇳','🇱🇨','🇵🇲',
      '🇻🇨','🇸🇩','🇸🇷','🇸🇪','🇨🇭','🇸🇾','🇹🇼','🇹🇯','🇹🇿','🇹🇭',
      '🇹🇱','🇹🇬','🇹🇰','🇹🇴','🇹🇹','🇹🇳','🇹🇷','🇹🇲','🇹🇨','🇹🇻',
      '🇺🇬','🇺🇦','🇦🇪','🇬🇧','🇺🇸','🇺🇾','🇺🇿','🇻🇺','🇻🇦','🇻🇪',
      '🇻🇳','🇼🇫','🇪🇭','🇾🇪','🇿🇲','🇿🇼','🏴󠁧󠁢󠁥󠁮󠁧󠁿','🏴󠁧󠁢󠁳󠁣󠁴󠁿','🏴󠁧󠁢󠁷󠁬󠁳󠁿',
    ],
  ),
];

/// Simple keyword map for search — matches the web's `keywordHints`.
const _keywordMap = <String, List<String>>{
  '😀': ['grin','smile','happy'],
  '😂': ['joy','tears','lol','laugh'],
  '🤣': ['rofl','laugh'],
  '😍': ['love','heart','eyes'],
  '😘': ['kiss'],
  '😎': ['cool','sunglasses'],
  '🤔': ['thinking','hmm'],
  '😢': ['sad','cry'],
  '😭': ['sob','cry'],
  '😡': ['angry','mad'],
  '🥳': ['party','celebrate'],
  '😴': ['sleep','zzz'],
  '👍': ['thumbs','up','ok','yes','like'],
  '👎': ['thumbs','down','no','dislike'],
  '👏': ['clap','applause'],
  '🙏': ['pray','please','thanks','namaste'],
  '❤️': ['heart','love','red'],
  '🔥': ['fire','lit','hot'],
  '✨': ['sparkle','shine'],
  '🎉': ['party','tada','celebrate'],
  '💯': ['100','perfect'],
  '💔': ['broken','heart'],
  '🍕': ['pizza','food'],
  '🍔': ['burger','food'],
  '☕': ['coffee','tea','drink'],
  '🍺': ['beer','drink'],
  '🎂': ['cake','birthday'],
  '⚽': ['soccer','football','sport'],
  '🏀': ['basketball','sport'],
  '🎮': ['game','controller'],
  '✈️': ['plane','flight','travel'],
  '🚗': ['car','drive'],
  '🚀': ['rocket','launch'],
  '🏠': ['home','house'],
  '📱': ['phone','mobile'],
  '💻': ['laptop','computer'],
  '📷': ['camera','photo'],
  '💡': ['idea','light'],
  '🔒': ['lock','secure'],
  '✅': ['check','done','yes'],
  '❌': ['x','wrong','no'],
  '⭐': ['star'],
  '🌙': ['moon','night'],
  '☀️': ['sun','day'],
  '🌈': ['rainbow'],
  '🐶': ['dog','puppy'],
  '🐱': ['cat','kitten'],
  '🌸': ['flower','cherry','blossom'],
  '🌹': ['rose','flower'],
  '🎁': ['gift','present'],
  '🏆': ['trophy','win'],
  '🇵🇰': ['pakistan','pk'],
  '🇮🇳': ['india'],
  '🇺🇸': ['usa','america'],
  '🇬🇧': ['uk','britain','england'],
  '🇸🇦': ['saudi','arabia'],
  '🇦🇪': ['uae','dubai'],
};

List<String> _searchEmojis(String query) {
  if (query.isEmpty) return [];
  final q = query.toLowerCase();
  final results = <String>[];
  final seen = <String>{};
  for (final cat in _categories) {
    if (cat.id == 'recent') continue;
    for (final e in cat.emojis) {
      if (seen.contains(e) || results.length >= 128) continue;
      final keywords = _keywordMap[e] ?? [];
      final catHit = cat.id.contains(q) || cat.label.toLowerCase().contains(q);
      final kwHit = keywords.any((k) => k.contains(q) || q.contains(k));
      final emojiHit = e.contains(q);
      if (catHit || kwHit || emojiHit) {
        seen.add(e);
        results.add(e);
      }
    }
  }
  return results;
}

/// Full-featured emoji picker widget designed to sit inline below the composer.
class EmojiPickerWidget extends StatefulWidget {
  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    required this.colors,
    this.height = 280,
  });

  final ValueChanged<String> onEmojiSelected;
  final QcColors colors;
  final double height;

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  int _categoryIndex = 1; // skip "recent" if empty
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final List<String> _recent = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTap(String emoji) {
    widget.onEmojiSelected(emoji);
    // Update recent
    _recent.remove(emoji);
    _recent.insert(0, emoji);
    if (_recent.length > 24) _recent.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final isSearching = _searchQuery.isNotEmpty;

    List<String> emojis;
    if (isSearching) {
      emojis = _searchEmojis(_searchQuery);
    } else if (_categoryIndex == 0) {
      emojis = _recent;
    } else {
      emojis = _categories[_categoryIndex].emojis;
    }

    return Container(
      height: widget.height,
      color: c.surface,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search emoji…',
                prefixIcon: Icon(Icons.search, size: 20, color: c.textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          // Grid
          Expanded(
            child: emojis.isEmpty
                ? Center(
                    child: Text(
                      isSearching ? 'No emoji found' : 'No recent emoji',
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (ctx, i) => GestureDetector(
                      onTap: () => _onTap(emojis[i]),
                      child: Center(
                        child: Text(emojis[i], style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),
          ),
          // Category tabs
          if (!isSearching)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: List.generate(_categories.length, (i) {
                  final cat = _categories[i];
                  final selected = i == _categoryIndex;
                  if (i == 0 && _recent.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _categoryIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: selected ? c.accent : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Icon(
                          cat.icon,
                          size: 20,
                          color: selected ? c.accent : c.textMuted,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
