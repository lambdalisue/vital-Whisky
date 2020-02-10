# vital-Whisky

[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)

[![reviewdog](https://github.com/lambdalisue/vital-Whisky/workflows/reviewdog/badge.svg)](https://github.com/lambdalisue/vital-Whisky/actions?query=workflow%3Areviewdog)
[![vim](https://github.com/lambdalisue/vital-Whisky/workflows/vim/badge.svg)](https://github.com/lambdalisue/vital-Whisky/actions?query=workflow%3Avim)
[![neovim](https://github.com/lambdalisue/vital-Whisky/workflows/neovim/badge.svg)](https://github.com/lambdalisue/vital-Whisky/actions?query=workflow%3Aneovim)

A [vital.vim](https://github.com/vim-jp/vital.vim) external module collection.

**Note that all modules in this repository are experimental and may be removed.**

## Modules

| Name                                                                             | Description                               | Remark     |
| -------------------------------------------------------------------------------- | ----------------------------------------- | ---------- |
| [`App.Emitter`](./doc/Vital/App/Emitter.txt)                                     | An event emitter with middleware support  | Deprecated |
| [`App.Flag`](./doc/Vital/App/Flag.txt)                                           | A simple command argument library         | Deprecated |
| [`App.Revelator`](./doc/Vital/App/Revelator.txt)                                 | Use exception to show messages            | Deprecated |
| [`App.Spinner`](./doc/Vital/App/Spinner.txt)                                     | ASCII spinner collection                  | Deprecated |
| [`Async.Observable.Process`](./doc/Vital/Async/Observable/Process.txt)           | `Async.Observable` based process module   |            |
| [`Async.Promise.Deferred`](./doc/Vital/Async/Promise/Deferred.txt)               | `Async.Promise` based deferred module     |            |
| [`Async.Promise.Process`](./doc/Vital/Async/Promise/Process.txt)                 | `Async.Promise` based process module      |            |
| [`Async.CancellationToken`](./doc/Vital/Async/CancellationToken.txt)             | CancellationToken to cancel promise       |            |
| [`Async.CancellationTokenSource`](./doc/Vital/Async/CancellationTokenSource.txt) | CancellationTokenSource to cancel promise |            |
| [`Async.File`](./doc/Vital/Async/File.txt)                                       | Asynchronous version of `System.File`     |            |
| [`Async.Lambda`](./doc/Vital/Async/Lambda.txt)                                   | Asynchronous version of `Lambda`          |            |
| [`Async.Observable`](./doc/Vital/Async/Observable.txt)                           | A minimal Observable                      |            |
| [`Data.List.Chunker`](./doc/Vital/Data/List/Chunker.txt)                         | Make chunks from a list                   |            |
| [`System.Job`](./doc/Vital/System/Job.txt)                                       | Vim/Neovim compatible layer of job        |            |
| [`System.Sandbox`](./doc/Vital/System/Sandbox.txt)                               | Create a sandbox directory for tests      |            |
| [`Vim.Buffer.ANSI`](./doc/Vital/Vim/Buffer/ANSI.txt)                             | Use conceal to show ANSI color            | Deprecated |
| [`Vim.Buffer.Group`](./doc/Vital/Vim/Buffer/Group.txt)                           | Create a buffer group                     | Deprecated |
| [`Vim.Buffer.Opener`](./doc/Vital/Vim/Buffer/Opener.txt)                         | Open a buffer in numerous way             | Deprecated |
| [`Vim.Buffer.Writer`](./doc/Vital/Vim/Buffer/Writer.txt)                         | Write content to a buffer                 | Deprecated |
| [`Vim.Console`](./doc/Vital/Vim/Console.txt)                                     | Console                                   | Deprecated |
| [`Vim.Highlight`](./doc/Vital/Vim/Highlight.txt)                                 | Highlight library                         | Deprecated |
| [`Vim.Window`](./doc/Vital/Vim/Window.txt)                                       | Window library                            | Deprecated |
| `Vim.Window.Cursor`                                                              | Window cursor library                     | Deprecated |
| `Vim.Window.Locator`                                                             | Window locator library                    | Deprecated |
| `Vim.Window.Selector`                                                            | Window selector library                   | Deprecated |
| [`Config`](./doc/Vital/Config.txt)                                               | Script config utility                     |            |
| [`Lambda`](./doc/Vital/Lambda.txt)                                               | Lambda function utility                   |            |
| [`Prompt`](./doc/Vital/Prompt.txt)                                               | Prompt                                    | Deprecated |

# License

The code in this repository follows MIT license texted in [LICENSE](./LICENSE).
Contributors need to agree that any modifications sent in this repository follow the license.
