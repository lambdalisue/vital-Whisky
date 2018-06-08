scriptencoding utf-8

function! s:_vital_created(module) abort
  " https://github.com/sindresorhus/cli-spinners
  let a:module.dots = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
  let a:module.dots2 = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷']
  let a:module.dots3 = ['⠋', '⠙', '⠚', '⠞', '⠖', '⠦', '⠴', '⠲', '⠳', '⠓']
  let a:module.dots4 = ['⠄', '⠆', '⠇', '⠋', '⠙', '⠸', '⠰', '⠠', '⠰', '⠸', '⠙', '⠋', '⠇', '⠆']
  let a:module.dots5 = ['⠋', '⠙', '⠚', '⠒', '⠂', '⠂', '⠒', '⠲', '⠴', '⠦', '⠖', '⠒', '⠐', '⠐', '⠒', '⠓', '⠋']
  let a:module.dots6 = ['⠁', '⠉', '⠙', '⠚', '⠒', '⠂', '⠂', '⠒', '⠲', '⠴', '⠤', '⠄', '⠄', '⠤', '⠴', '⠲', '⠒', '⠂', '⠂', '⠒', '⠚', '⠙', '⠉', '⠁']
  let a:module.dots7 = ['⠈', '⠉', '⠋', '⠓', '⠒', '⠐', '⠐', '⠒', '⠖', '⠦', '⠤', '⠠', '⠠', '⠤', '⠦', '⠖', '⠒', '⠐', '⠐', '⠒', '⠓', '⠋', '⠉', '⠈']
  let a:module.dots8 = ['⠁', '⠁', '⠉', '⠙', '⠚', '⠒', '⠂', '⠂', '⠒', '⠲', '⠴', '⠤', '⠄', '⠄', '⠤', '⠠', '⠠', '⠤', '⠦', '⠖', '⠒', '⠐', '⠐', '⠒', '⠓', '⠋', '⠉', '⠈', '⠈']
  let a:module.dots9 = ['⢹', '⢺', '⢼', '⣸', '⣇', '⡧', '⡗', '⡏']
  let a:module.dots10 = ['⢄', '⢂', '⢁', '⡁', '⡈', '⡐', '⡠']
  let a:module.dots11 = ['⠁', '⠂', '⠄', '⡀', '⢀', '⠠', '⠐', '⠈']
  let a:module.dots12 = ['⢀⠀', '⡀⠀', '⠄⠀', '⢂⠀', '⡂⠀', '⠅⠀', '⢃⠀', '⡃⠀', '⠍⠀', '⢋⠀', '⡋⠀', '⠍⠁', '⢋⠁', '⡋⠁', '⠍⠉', '⠋⠉', '⠋⠉', '⠉⠙', '⠉⠙', '⠉⠩', '⠈⢙', '⠈⡙', '⢈⠩', '⡀⢙', '⠄⡙', '⢂⠩', '⡂⢘', '⠅⡘', '⢃⠨', '⡃⢐', '⠍⡐', '⢋⠠', '⡋⢀', '⠍⡁', '⢋⠁', '⡋⠁', '⠍⠉', '⠋⠉', '⠋⠉', '⠉⠙', '⠉⠙', '⠉⠩', '⠈⢙', '⠈⡙', '⠈⠩', '⠀⢙', '⠀⡙', '⠀⠩', '⠀⢘', '⠀⡘', '⠀⠨', '⠀⢐', '⠀⡐', '⠀⠠', '⠀⢀', '⠀⡀']
  let a:module.line = ['-', '\\', '|', '/']
  let a:module.line2 = ['⠂', '-', '–', '—', '–', '-']
  let a:module.pipe = ['┤', '┘', '┴', '└', '├', '┌', '┬', '┐']
  let a:module.simpleDots = ['.  ', '.. ', '...', '   ']
  let a:module.simpleDotsScrolling = ['.  ', '.. ', '...', ' ..', '  .', '   ']
  let a:module.star = ['✶', '✸', '✹', '✺', '✹', '✷']
  let a:module.star2 = ['+', 'x', '*']
  let a:module.flip = ['_', '_', '_', '-', '`', '`', "'", '´', '-', '_', '_', '_']
  let a:module.hamburger = ['☱', '☲', '☴']
  let a:module.growVertical = ['▁', '▃', '▄', '▅', '▆', '▇', '▆', '▅', '▄', '▃']
  let a:module.growHorizontal = ['▏', '▎', '▍', '▌', '▋', '▊', '▉', '▊', '▋', '▌', '▍', '▎']
  let a:module.balloon = [' ', '.', 'o', 'O', '@', '*', ' ']
  let a:module.balloon2 = ['.', 'o', 'O', '°', 'O', 'o', '.']
  let a:module.noise = ['▓', '▒', '░']
  let a:module.bounce = ['⠁', '⠂', '⠄', '⠂']
  let a:module.boxBounce = ['▖', '▘', '▝', '▗']
  let a:module.boxBounce2 = ['▌', '▀', '▐', '▄']
  let a:module.triangle = ['◢', '◣', '◤', '◥']
  let a:module.arc = ['◜', '◠', '◝', '◞', '◡', '◟']
  let a:module.circle = ['◡', '⊙', '◠']
  let a:module.squareCorners = ['◰', '◳', '◲', '◱']
  let a:module.circleQuarters = ['◴', '◷', '◶', '◵']
  let a:module.circleHalves = ['◐', '◓', '◑', '◒']
  let a:module.squish = ['╫', '╪']
  let a:module.toggle = ['⊶', '⊷']
  let a:module.toggle2 = ['▫', '▪']
  let a:module.toggle3 = ['□', '■']
  let a:module.toggle4 = ['■', '□', '▪', '▫']
  let a:module.toggle5 = ['▮', '▯']
  let a:module.toggle6 = ['ဝ', '၀']
  let a:module.toggle7 = ['⦾', '⦿']
  let a:module.toggle8 = ['◍', '◌']
  let a:module.toggle9 = ['◉', '◎']
  let a:module.toggle10 = ['㊂', '㊀', '㊁']
  let a:module.toggle11 = ['⧇', '⧆']
  let a:module.toggle12 = ['☗', '☖']
  let a:module.toggle13 = ['=', '*', '-']
  let a:module.arrow = ['←', '↖', '↑', '↗', '→', '↘', '↓', '↙']
  let a:module.arrow2 = ['⬆️ ', '↗️ ', '➡️ ', '↘️ ', '⬇️ ', '↙️ ', '⬅️ ', '↖️ ']
  let a:module.arrow3 = ['▹▹▹▹▹', '▸▹▹▹▹', '▹▸▹▹▹', '▹▹▸▹▹', '▹▹▹▸▹', '▹▹▹▹▸']
  let a:module.bouncingBar = ['[    ]', '[=   ]', '[==  ]', '[=== ]', '[ ===]', '[  ==]', '[   =]', '[    ]', '[   =]', '[  ==]', '[ ===]', '[====]', '[=== ]', '[==  ]', '[=   ]']
  let a:module.bouncingBall = ['( ●    )', '(  ●   )', '(   ●  )', '(    ● )', '(     ●)', '(    ● )', '(   ●  )', '(  ●   )', '( ●    )', '(●     )']
  let a:module.smiley = ['😄 ', '😝 ']
  let a:module.monkey = ['🙈 ', '🙈 ', '🙉 ', '🙊 ']
  let a:module.hearts = ['💛 ', '💙 ', '💜 ', '💚 ', '❤️ ']
  let a:module.clock = ['🕛 ', '🕐 ', '🕑 ', '🕒 ', '🕓 ', '🕔 ', '🕕 ', '🕖 ', '🕗 ', '🕘 ', '🕙 ', '🕚 ']
  let a:module.earth = ['🌍 ', '🌎 ', '🌏 ']
  let a:module.moon = ['🌑 ', '🌒 ', '🌓 ', '🌔 ', '🌕 ', '🌖 ', '🌗 ', '🌘 ']
  let a:module.runner = ['🚶 ', '🏃 ']
  let a:module.pong = ['▐⠂       ▌', '▐⠈       ▌', '▐ ⠂      ▌', '▐ ⠠      ▌', '▐  ⡀     ▌', '▐  ⠠     ▌', '▐   ⠂    ▌', '▐   ⠈    ▌', '▐    ⠂   ▌', '▐    ⠠   ▌', '▐     ⡀  ▌', '▐     ⠠  ▌', '▐      ⠂ ▌', '▐      ⠈ ▌', '▐       ⠂▌', '▐       ⠠▌', '▐       ⡀▌', '▐      ⠠ ▌', '▐      ⠂ ▌', '▐     ⠈  ▌', '▐     ⠂  ▌', '▐    ⠠   ▌', '▐    ⡀   ▌', '▐   ⠠    ▌', '▐   ⠂    ▌', '▐  ⠈     ▌', '▐  ⠂     ▌', '▐ ⠠      ▌', '▐ ⡀      ▌', '▐⠠       ▌']
  let a:module.shark = ['▐|\\____________▌', '▐_|\\___________▌', '▐__|\\__________▌', '▐___|\\_________▌', '▐____|\\________▌', '▐_____|\\_______▌', '▐______|\\______▌', '▐_______|\\_____▌', '▐________|\\____▌', '▐_________|\\___▌', '▐__________|\\__▌', '▐___________|\\_▌', '▐____________|\\▌', '▐____________/|▌', '▐___________/|_▌', '▐__________/|__▌', '▐_________/|___▌', '▐________/|____▌', '▐_______/|_____▌', '▐______/|______▌', '▐_____/|_______▌', '▐____/|________▌', '▐___/|_________▌', '▐__/|__________▌', '▐_/|___________▌', '▐/|____________▌']
  let a:module.dqpb = ['d', 'q', 'p', 'b']
  let a:module.weather = ['☀️ ', '☀️ ', '☀️ ', '🌤 ', '⛅️ ', '🌥 ', '☁️ ', '🌧 ', '🌨 ', '🌧 ', '🌨 ', '🌧 ', '🌨 ', '⛈ ', '🌨 ', '🌧 ', '🌨 ', '☁️ ', '🌥 ', '⛅️ ', '🌤 ', '☀️ ', '☀️ ']
  let a:module.christmas = ['🌲', '🎄']
  let a:module.grenade = ['،   ', '′   ', ' ´ ', ' ‾ ', '  ⸌', '  ⸊', '  |', '  ⁎', '  ⁕', ' ෴ ', '  ⁓', '   ', '   ', '   ']
  let a:module.point = ['∙∙∙', '●∙∙', '∙●∙', '∙∙●', '∙∙∙']
  let a:module.layer = ['-', '=', '≡']
endfunction

function! s:new(frames) abort
  return {
        \ '_index': -1,
        \ '_length': len(a:frames),
        \ '_frames': a:frames,
        \ 'next': funcref('s:_spinner_next'),
        \ 'reset': funcref('s:_spinner_reset'),
        \}
endfunction


function! s:_spinner_next() abort dict
  let self._index += 1
  let self._index = self._index % self._length
  return self._frames[self._index]
endfunction

function! s:_spinner_reset() abort dict
  let self._index = -1
endfunction
