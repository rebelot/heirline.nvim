# Changelog

## [1.0.3](https://github.com/rebelot/heirline.nvim/compare/v1.0.2...v1.0.3) (2024-02-12)


### Bug Fixes

* **cookbook:** migrate from `nvim_buf_get_option` to `nvim_get_option_value` ([512ff09](https://github.com/rebelot/heirline.nvim/commit/512ff096d427ade3ca11e18f7b0a6f1819095a45))

## [1.0.2](https://github.com/rebelot/heirline.nvim/compare/v1.0.1...v1.0.2) (2023-11-29)


### Bug Fixes

* **winbar:** don't modify winbar for disabled buffers ([7ee3553](https://github.com/rebelot/heirline.nvim/commit/7ee355330b9c6c3d4a43c6f22bc78364ea9acac7))

## [1.0.1](https://github.com/rebelot/heirline.nvim/compare/v1.0.0...v1.0.1) (2023-09-03)


### Bug Fixes

* **cookbook:** avoid resetting showtabline if already at default value ([daf91db](https://github.com/rebelot/heirline.nvim/commit/daf91dbf9a975f078a6764d537da7aa28ca0c519))

## 1.0.0 (2023-07-05)


### ⚠ BREAKING CHANGES

* **winbar:** better way to disable per-window winbar. Add docs. Fix #114
* **statuscolumn:** 
* **flexible_components:** promote flexible components to "builtin"
* **tabline:** do not set showtabline. Fix #73
* **fallthrough:** add fallthrough to control evaluation of components with conditions and deprecate utils.pick_child_on_condition.
* **tabline:** add is_visible field to buflist and remove hardcoded %=, remove min_tab and close button from make_tablist
* **statusline:** various improvements:
* **on_click:** add minwid field and document how to pass window handler; remove winid from callback arguments.
* **utils:** prepend '_' to private attributes
* **highlights:** utils.get_highlight() return value is compliant with highlight api
* **highlights:** improve highlight normalization; privatize highlight functions; add module-level get_highlights() function
* **cookbook:** add documentation for new functionality + minor upgrades.
* **statusline:** remove stop_when in favor of the more versatile pick_child.
* **flexible_components:** 
* **elastic_components:** allow make_elastic_components accept
* **statusline:** stop_at_first -> stop_when(self, child_out)

### Features

* add tabpage handle to tablist components ([d000fc1](https://github.com/rebelot/heirline.nvim/commit/d000fc120143a936606747daf273daa7af7f5c3c))
* **autcmd_update:** improve cache handling; this improves coordination between updatable_components and components which require special post-processing ([08b7998](https://github.com/rebelot/heirline.nvim/commit/08b7998c6a3cbb9202350e6fe4e1a298ec703947))
* **buflist utilities:** allow disabling of buflist cache ([cb41496](https://github.com/rebelot/heirline.nvim/commit/cb41496f140bedc03b7d28ca68990aa267e8edd4))
* **buflist:** allow creation of multiple buflists; allow passing custom function to retrieve bufnr handlers ([33706b4](https://github.com/rebelot/heirline.nvim/commit/33706b4ea94a18777af80eafa1896da054ee69c8))
* **colors:** color aliases can be a function. Add config.opts.colors field ([5bce468](https://github.com/rebelot/heirline.nvim/commit/5bce46851ff353a86981d23acd5a4358cfb62734))
* **conditions:** add is_not_active condition ([7ee0572](https://github.com/rebelot/heirline.nvim/commit/7ee057285df1d4b14824a12ecc0c6552044dd685))
* **conditions:** buffer_matches accepts bufnr argument ([b5bbb8b](https://github.com/rebelot/heirline.nvim/commit/b5bbb8b4e4e24dccd4a2f20e38a2be0b58fb7fc5))
* **cookbook, dap:** add debugger clickable buttons example ([f1ad9d7](https://github.com/rebelot/heirline.nvim/commit/f1ad9d7260e06bb331c3318a1c8226baae230710))
* **cookbook, navic:** add 'CursorMoved' update ([19cab76](https://github.com/rebelot/heirline.nvim/commit/19cab76f52710ec67bd8829cbc96d0c322963090))
* **cookbook, navic:** improve navic component with multi-window support and clickable elements ([a9b1d88](https://github.com/rebelot/heirline.nvim/commit/a9b1d883a15f86caf6be76fc646744817d03ef34))
* **cookbook, navic:** improve navic component: add on_click; add highlights to basic version ([a35f1c2](https://github.com/rebelot/heirline.nvim/commit/a35f1c2b20962bfe4f5db91caa5c13225530fab4))
* **cookbook:** add SearchCount and MacroRec ([673226c](https://github.com/rebelot/heirline.nvim/commit/673226cbbb4da6f595a78cc03b18682f3c7b2bee))
* **cookbook:** add ShowCmd snippet ([e08e2c0](https://github.com/rebelot/heirline.nvim/commit/e08e2c03761722563649c25776eb3d7db20804bf))
* **cookbook:** add TablinePicker ([a94390e](https://github.com/rebelot/heirline.nvim/commit/a94390e0e8509944bfbd8265a5b4bb231d2d2954))
* **cookbook:** only show buflist if more than 1 buffer; fix [#122](https://github.com/rebelot/heirline.nvim/issues/122) ([c109ac0](https://github.com/rebelot/heirline.nvim/commit/c109ac026fd80ea12cd11f6af79f2e1a5de71e04))
* **elastic components:** add factory for elastic components: take1 ([c5582f2](https://github.com/rebelot/heirline.nvim/commit/c5582f297a7c37797ff3f16a11737a5f1620c95a))
* **elastic_components:** allow make_elastic_components accept ([31339a4](https://github.com/rebelot/heirline.nvim/commit/31339a40baabbdba25339787e883e10cc4ecef37))
* **events:** add before and after callbacks at evaluation time ([1f06385](https://github.com/rebelot/heirline.nvim/commit/1f063858a0b894083673b4d9af6cb2db3a8915f0))
* **events:** pass last output to before ([1f7cada](https://github.com/rebelot/heirline.nvim/commit/1f7cada813026ae5739a638e99b903f574ac8607))
* **fallthrough:** add fallthrough to control evaluation of components with conditions and deprecate utils.pick_child_on_condition. ([9941236](https://github.com/rebelot/heirline.nvim/commit/99412362e56870e4c277f962f706455e4010a050))
* **flexible_components:** feat(flexible_components):  ([a726746](https://github.com/rebelot/heirline.nvim/commit/a7267460e378f948de877d233487e161b98e7fb6))
* **flexible_components:** promote flexible components to "builtin" ([7bd7190](https://github.com/rebelot/heirline.nvim/commit/7bd719094a6b712e02b99e40aacd07c8eae871e2))
* **highlights:** support cterm 8-bit colors; fix [#36](https://github.com/rebelot/heirline.nvim/issues/36) ([60d92a6](https://github.com/rebelot/heirline.nvim/commit/60d92a6f8003c5f56fd521fbe9fec43c0c9b4d94))
* **highlights:** use api nvim_set_hl: ([1720ff5](https://github.com/rebelot/heirline.nvim/commit/1720ff5f6504877f63a56db32fd6705cc0e0dd0a))
* **highlights:** use api nvim_set_hl: ([2f60696](https://github.com/rebelot/heirline.nvim/commit/2f60696f2083e23aa68c010875151a1628d6a2c1))
* **highlights:** utils.get_highlight() return value is compliant with highlight api ([f44d8dd](https://github.com/rebelot/heirline.nvim/commit/f44d8dd6773662829f0cf0fb67e810c384c1744c))
* **hl:** add `force` kw ([269b316](https://github.com/rebelot/heirline.nvim/commit/269b31696a8c4a1a25190ad0c447109510dcc1c4))
* let callback function use all available parameters ([480badd](https://github.com/rebelot/heirline.nvim/commit/480badd3151fb20ec380f866df650c5acfd61bf7))
* **load_colors:** add load_colors() to create color name aliases. ([76fea23](https://github.com/rebelot/heirline.nvim/commit/76fea234eadc7d7716af04d6f2485ac00e3a2892))
* **make_buflist:** allow passing reference to custom cache table ([d340f95](https://github.com/rebelot/heirline.nvim/commit/d340f951c79f8f286f4bfcca912caa61e4471e7c))
* **on_click:** add minwid field and document how to pass window handler; remove winid from callback arguments. ([8ad1050](https://github.com/rebelot/heirline.nvim/commit/8ad105098b6b2075b5f482000a3d9aa5be873a29))
* **on_click:** allow callback to be a string. ([14779d6](https://github.com/rebelot/heirline.nvim/commit/14779d685da0e5ca64fcb110a7fd9074aca8d2cd))
* **on_click:** allow name to be a function ([1f307df](https://github.com/rebelot/heirline.nvim/commit/1f307dfc8d7b9119d7af6249880582920b25c37b))
* **on_click:** support binding lua callbacks to mouse clicks ([0271f3a](https://github.com/rebelot/heirline.nvim/commit/0271f3acf14751429180b3a16c608b119d9873b5))
* **on_colorscheme:** add on_colorscheme utility function ([c01c0f1](https://github.com/rebelot/heirline.nvim/commit/c01c0f149f1ed4d8ed08c9e8427c4167ed10bdd3))
* **statuscolumn:** provide initial support for statuscolumn option ([7b57b27](https://github.com/rebelot/heirline.nvim/commit/7b57b27e9e4d1ffa4f3e149f8fdc927db18a850a))
* **StatusLine:** add nonlocal base method ([2a3a76f](https://github.com/rebelot/heirline.nvim/commit/2a3a76f0148fd0a93e5e9b988e1fee2b58c641ee))
* **statusline:** add pick_child list to allow control on which ([71e43d4](https://github.com/rebelot/heirline.nvim/commit/71e43d42d5531986ee91a1c0d1c1f362e8a36ec1))
* **statusline:** add some utility methods ([cef435a](https://github.com/rebelot/heirline.nvim/commit/cef435a7d8665aaeeeed8c0c307aabaae348c439))
* **statusline:** give components an id; get component by id ([99b51ba](https://github.com/rebelot/heirline.nvim/commit/99b51baeb8e7c3a994a515c5f47f54c4db42e5ff))
* **statusline:** make component ids when loading ([c305391](https://github.com/rebelot/heirline.nvim/commit/c305391e847b94584cf1e6385a35dd7f4db88df3))
* **statusline:** stop_at_first -&gt; stop_when(self, child_out) ([8bbe790](https://github.com/rebelot/heirline.nvim/commit/8bbe790ec69531c6690f29c7dc204cfed447af2a))
* **statusline:** various improvements: ([09bf058](https://github.com/rebelot/heirline.nvim/commit/09bf05819339229f55889dab73986c12ee6197b7))
* **surround:** color in utils.surround can now be a function ([61507a7](https://github.com/rebelot/heirline.nvim/commit/61507a7d1cff565ec5b4eb95a74cb53ab4a3b02d))
* **tabline:** add is_visible field to buflist and remove hardcoded %=, remove min_tab and close button from make_tablist ([d07b07f](https://github.com/rebelot/heirline.nvim/commit/d07b07f94c6d7c1a834ab7366aee1621d6779508))
* **tabline:** do not set showtabline. Fix [#73](https://github.com/rebelot/heirline.nvim/issues/73) ([f46554a](https://github.com/rebelot/heirline.nvim/commit/f46554a0a4ea096867deb6ef8877cccbf5b7261b))
* **tabline:** experimental infrastructure for setting up tabline (part of it was leaked in previous commit) ([81d7a71](https://github.com/rebelot/heirline.nvim/commit/81d7a715637bcfdb9f375c200875f1622770d905))
* **timeit:** improve timeit function. Try it out to see how fast heirline is! ([496b86b](https://github.com/rebelot/heirline.nvim/commit/496b86b5125d70729ef48ceb765407a7d2ee12d2))
* **update/after:** add update and after fields. ([3188e22](https://github.com/rebelot/heirline.nvim/commit/3188e22589ff7990066113cd8f9bfc074611bf39))
* **update:** add autocommand callback ([a954dd2](https://github.com/rebelot/heirline.nvim/commit/a954dd2f59e9f8a9941f5460d888aa6770b4f19c))
* **update:** add pattern to update field; callback receieves autocmd args as second argument. ([d2767b3](https://github.com/rebelot/heirline.nvim/commit/d2767b3678069a5be31f0783b5309016f4720d59))
* **utils:** add count_chars function ([4cfbcc2](https://github.com/rebelot/heirline.nvim/commit/4cfbcc210a44dedc896e4653fa71d54051d48c76))
* **utils:** add insert() utility function ([d45256e](https://github.com/rebelot/heirline.nvim/commit/d45256ecb4227db194ef066d34f2cb9c90f495e0))
* **winbar:** add User HeirlineInitWinbar autocmd ([c5505f6](https://github.com/rebelot/heirline.nvim/commit/c5505f6db1d713d5b61251caa94cb9cd5e8b3504))
* **winbar:** allow hooking into winbar init autocmd via config.opts.winbar_blacklist_cb(autcmd_args) -&gt; bool (WIP) ([3677262](https://github.com/rebelot/heirline.nvim/commit/3677262fba12c2bc915afb8be150cec70392e678))
* **winbar:** better way to disable per-window winbar. Add docs. Fix [#114](https://github.com/rebelot/heirline.nvim/issues/114) ([5fa803c](https://github.com/rebelot/heirline.nvim/commit/5fa803cdf00c576585dbec431189471912637a25))
* **winbar:** set up window-local winbar and document how to disable it on certain buffers ([be8d39c](https://github.com/rebelot/heirline.nvim/commit/be8d39c33267252f75abeef55987b6c48bf032f0))
* **winbar:** width_percent_below is_winbar parameter ([164ef83](https://github.com/rebelot/heirline.nvim/commit/164ef83d4c651c9780b6b519d74ec35501755a4c))


### Bug Fixes

* add comma to COOKBOOK.md ([a63de38](https://github.com/rebelot/heirline.nvim/commit/a63de3864e1cebf17dfc7f4004c37e049a13701d))
* **autocmd:** check win height before setting up winbar; fix [#49](https://github.com/rebelot/heirline.nvim/issues/49) ([203f6f9](https://github.com/rebelot/heirline.nvim/commit/203f6f9bc213383caae9988f3be66051c7875b07))
* **broadcast:** correctly apply function to all nodes including the starting one ([290159b](https://github.com/rebelot/heirline.nvim/commit/290159b496008c89fda7be50b77cdc301ef8088e))
* **buflist utilities:** use buf_func with cache ([90416e2](https://github.com/rebelot/heirline.nvim/commit/90416e2d04378955be6867fb6c4d8d2417fb3f74))
* **buflist:** check if buffer is valid outside of cache. buf_func does not need to check if buf is valid. ([8a98c7d](https://github.com/rebelot/heirline.nvim/commit/8a98c7d3b688fc30cbd967f2beb385f93baddcdc))
* **buflist:** fix pagination logic ([4867a7c](https://github.com/rebelot/heirline.nvim/commit/4867a7cc543220af8818ce94138fbc75b7614a01))
* **conditions:** fix has_diagnosticS ([04a30f3](https://github.com/rebelot/heirline.nvim/commit/04a30f3a368c17f921e9eb24de2d3ee065bbeee5))
* **conditions:** lsp_attached ([ed12e0f](https://github.com/rebelot/heirline.nvim/commit/ed12e0f13b3ed7f699e51e0c830c9d4c11f142cc))
* **cookbook:** added missing return statement in example ([88555f3](https://github.com/rebelot/heirline.nvim/commit/88555f36d474b2c4b524eb9cced7dd5fd3a80751))
* **cookbook:** don't use alias for autocmd ([2c03277](https://github.com/rebelot/heirline.nvim/commit/2c032777a88fd1b17584a9a09ba8217b6948c541))
* **cookbook:** file readonly flag not showed ([e01a5d9](https://github.com/rebelot/heirline.nvim/commit/e01a5d9ee8e7d66a2fe4c99a0a4d2569609131bb))
* **cookbook:** filename and workdir ([e055e17](https://github.com/rebelot/heirline.nvim/commit/e055e17539397ada498154dd083dc6f3f8b862a9))
* **cookbook:** fix autocmd for conditional tabline when nbufs &gt; 1 ([9c6ac77](https://github.com/rebelot/heirline.nvim/commit/9c6ac77240df3038d0774376ede7978c9746509a))
* **cookbook:** fix missing return in tblinefileflags(modified) ([f4cfb5c](https://github.com/rebelot/heirline.nvim/commit/f4cfb5cf353e1eb14065b8a57860dfedb55f4c5b))
* **cookbook:** fix padding in Ruler ([cd30484](https://github.com/rebelot/heirline.nvim/commit/cd30484493780eb4daf3cd57b975f4af16fe849e))
* **cookbook:** fix provider signature ([414ad38](https://github.com/rebelot/heirline.nvim/commit/414ad3864895753d1ac1b50ee64609eb904d9a88))
* **cookbook:** fix redrawtabline on TablineCloseButton; fix [#140](https://github.com/rebelot/heirline.nvim/issues/140) ([2aed06a](https://github.com/rebelot/heirline.nvim/commit/2aed06a3a04c877dc64834e9b9dabf6ad3491bc8))
* **cookbook:** fix typo ([3ca917d](https://github.com/rebelot/heirline.nvim/commit/3ca917d9891ca592da2bbad32967ac1e5bb6243d))
* **cookbook:** fix vim.api call in ScrollBar ([26a7e30](https://github.com/rebelot/heirline.nvim/commit/26a7e30d4dde0dddcb31d95ccd20b1c36d6bb32b))
* **cookbook:** link to statusline obj ([5fb6252](https://github.com/rebelot/heirline.nvim/commit/5fb625295567c5a8553fe15df8dda7c3654c63fe))
* **cookbook:** modified condition in the TablineFileFlags ([639e210](https://github.com/rebelot/heirline.nvim/commit/639e210a02e72174e38a1cd7e5c8c792fd42492a))
* **cookbook:** nvim-web-devicons link ([b02bd6f](https://github.com/rebelot/heirline.nvim/commit/b02bd6fa5840308696f138765773e0c147cc42cd))
* **cookbook:** revert previous snippet; more work is needed. ([2a57f80](https://github.com/rebelot/heirline.nvim/commit/2a57f80c6ec671c395494d7a7d055ac586eaefd4))
* **docs:** FileName -&gt; FileNameBlock; fix [#121](https://github.com/rebelot/heirline.nvim/issues/121) ([5494bdf](https://github.com/rebelot/heirline.nvim/commit/5494bdf9bfa11d7b41ceee160353ad93f3a8dfa3))
* **docs:** update ToC ([1377058](https://github.com/rebelot/heirline.nvim/commit/13770584ec05543e8ac5cfc00e76f85d67e1344d))
* **eval:** fix regression with unified _eval, add winnr ([6ad825c](https://github.com/rebelot/heirline.nvim/commit/6ad825c61c9d95b5d8177ae0e6101986970b092d))
* **expandable_components:** override priorities of nested expandables ([bfcabb1](https://github.com/rebelot/heirline.nvim/commit/bfcabb13d0b234c3b9e41225ca981f72f1616135))
* **expandables:** allow nesting of expandable components ([5828b3d](https://github.com/rebelot/heirline.nvim/commit/5828b3d4d5fef336bf918145956ba131aa6cb2ac))
* **expandables:** make 'em work. ([483c56a](https://github.com/rebelot/heirline.nvim/commit/483c56a2736e4775862f9b44820ce605df12dd87))
* **flexible_components:** better checking of maximum available space ([3ea10b6](https://github.com/rebelot/heirline.nvim/commit/3ea10b62f26936ed0d918c9a1762e64dbd6cb5ed))
* **flexible_components:** check for siblings in group flexible components, correct priorities and improve sorting ([#80](https://github.com/rebelot/heirline.nvim/issues/80)). ([46d6939](https://github.com/rebelot/heirline.nvim/commit/46d6939cdaecca5b1a680858420b430aad64ad4d))
* **flexible_components:** pass full_width to _eval ([ad4ddf4](https://github.com/rebelot/heirline.nvim/commit/ad4ddf45ec469cd544604330cce13d74685af95b))
* **get_bufs:** also list unloaded buffer, use nvim_buf_get_option (faster) ([440da6b](https://github.com/rebelot/heirline.nvim/commit/440da6bcf4ddec7bd72f47da02a72909615cfe04))
* **get_highlight:** use rawget \[#22](https://github.com/rebelot/heirline.nvim/issues/22) ([4451c0f](https://github.com/rebelot/heirline.nvim/commit/4451c0fca66efe1b2fc105fadc88988affc92d40))
* **highlight:** fix typo in get_highlight; check for termguicolors dynamically ([9202f4f](https://github.com/rebelot/heirline.nvim/commit/9202f4f0de80e722e177c61d87857caddd6e3f1e))
* **highlights:** fix(highlights):  ([f9e7b48](https://github.com/rebelot/heirline.nvim/commit/f9e7b48ba38e2a2b9d7be3b4b1865b06130edb64))
* **highlights:** always prioritize abbreviations ([24c05f6](https://github.com/rebelot/heirline.nvim/commit/24c05f626e0cef1da84704266c94f2aa27209e0e))
* **highlights:** do not fail on blank hlgroups; fix [#110](https://github.com/rebelot/heirline.nvim/issues/110) ([b2e69dc](https://github.com/rebelot/heirline.nvim/commit/b2e69dc3385772159b5dffd3a12a7af874692e10))
* **hl:** do not resolve hlgroup name on instantiation, fix [#78](https://github.com/rebelot/heirline.nvim/issues/78); Also improve hl logic ([5630b0d](https://github.com/rebelot/heirline.nvim/commit/5630b0d8d23e44ff874a3678a17d30a49b533eba))
* **hl:** handle nil return of hl function ([7a46e28](https://github.com/rebelot/heirline.nvim/commit/7a46e2885245fe3a57ac8d3e100185fc58f02f72))
* **name_hl:** make inferring highlight style more robust. ([e1cada8](https://github.com/rebelot/heirline.nvim/commit/e1cada8ab756d8d32ba246f1989a4490a9780734))
* nvim-navic example ([bc96864](https://github.com/rebelot/heirline.nvim/commit/bc96864f61362926590c9a9aae13a0e0367ab7e1))
* **on_click:** pass winid to on_click callback ([c13b7d8](https://github.com/rebelot/heirline.nvim/commit/c13b7d8b0136b9cbf0e2f10fef3a468b19cf573b))
* **on_click:** place @ before provider ([7b4aabc](https://github.com/rebelot/heirline.nvim/commit/7b4aabc2c55d50fbd4a4923e847079d6fa9a8613))
* **on_colorscheme:** also update winbar and tabline on colorscheme changes; fix [#127](https://github.com/rebelot/heirline.nvim/issues/127) ([110ddc5](https://github.com/rebelot/heirline.nvim/commit/110ddc5165da9a145e8456b39dac031954365631))
* **pick_child:** fix typo ([2e76280](https://github.com/rebelot/heirline.nvim/commit/2e7628032dcf77cec4a117d5626c0e986c4025d4))
* **priority:** allow discontinuous priority values ([0e7565e](https://github.com/rebelot/heirline.nvim/commit/0e7565ea7a38ed5d815fcac0d3db359821561011))
* recreate tab components correctly when a tabpage is deleted ([8009b77](https://github.com/rebelot/heirline.nvim/commit/8009b77937b77b9faa14685d7ad70ecd124e6c79))
* **statusline:** fix `restrict` behavior. ([395a8a8](https://github.com/rebelot/heirline.nvim/commit/395a8a849aa6fbdad70fd5660861a7f71ec86eb8))
* **statusline:** fix restrict behavior. ([93c75cb](https://github.com/rebelot/heirline.nvim/commit/93c75cbe231573fe43bfb8f98491a83dfe44d504))
* **tabline:** correct buffer filtering. ([6cfce84](https://github.com/rebelot/heirline.nvim/commit/6cfce84a32aa9231ca764aee2fdd9a88db3f3eb9))
* **tests:** fix plenary path (lazy) ([81ceb30](https://github.com/rebelot/heirline.nvim/commit/81ceb3025e6c7030c42accc3951dad94f31ff0c8))
* **timeit:** ipairs -&gt; pairs ([aa21485](https://github.com/rebelot/heirline.nvim/commit/aa214859a69bd8dbd23f76cfbf34521e8bbf9635))
* **traverse:** guard _tree with rawget; [#79](https://github.com/rebelot/heirline.nvim/issues/79) ([b6044c8](https://github.com/rebelot/heirline.nvim/commit/b6044c8d650904f205999e6eea0dae81b38b713f))
* **tree:** move tree generation on top of _eval; check for missing _tree in traverse(); fix [#53](https://github.com/rebelot/heirline.nvim/issues/53) ([f7239b1](https://github.com/rebelot/heirline.nvim/commit/f7239b1f01b9596a4b52d8b8c017b4339992009b))
* typo in README ([5e3bed2](https://github.com/rebelot/heirline.nvim/commit/5e3bed2e662b03dea7bbc984e859f56c30967f5a))
* **update:** dont set _win_cache during component eval ([#79](https://github.com/rebelot/heirline.nvim/issues/79)) ([db41ad4](https://github.com/rebelot/heirline.nvim/commit/db41ad446db88c2057d54537b6ebab77d6a45bb6))
* **update:** fix typo in update function, fix [#63](https://github.com/rebelot/heirline.nvim/issues/63) ([9179b71](https://github.com/rebelot/heirline.nvim/commit/9179b71d9967057814e5920ecb3c8322073825ea))
* **utils:** add nvim_eval_statusline to count_chars ([8a658f1](https://github.com/rebelot/heirline.nvim/commit/8a658f1276bc38e04adce2848c8a95ecbe07c3ea))
* **win_attr:** improve behavior of get_win_attr; add cleanup to set_win_attr ([8278dc8](https://github.com/rebelot/heirline.nvim/commit/8278dc8371d63bda0e148f59b4ccb84c6989b87f))
* **winbar+terminal:** exec disable_winbar_cb on TermOpen; fix [#137](https://github.com/rebelot/heirline.nvim/issues/137) ([d860874](https://github.com/rebelot/heirline.nvim/commit/d860874eef6088109b5cb102871d76307280f052))
* **winbar:** add VimEnter event to Heirline_init_winbar autocmd; fix [#44](https://github.com/rebelot/heirline.nvim/issues/44) ([bbd74de](https://github.com/rebelot/heirline.nvim/commit/bbd74def4189b03ac4c646293f701c51c98af671))
* **winbar:** do not set up winbar if window height is &lt;=1; [#136](https://github.com/rebelot/heirline.nvim/issues/136) ([f4b7ff8](https://github.com/rebelot/heirline.nvim/commit/f4b7ff8848c9dc5462040c849acd76b46de68e99))
* **winbar:** fix init autocmd when called from VimEnter/UIEnter events; remove floating check (waiting for issues...) ([8fb1f07](https://github.com/rebelot/heirline.nvim/commit/8fb1f07e586a8e601bd1c7b76aebc6e51ad7d5b0))
* **winbar:** make efforts not to setup winbar if window is floating ([7684d4b](https://github.com/rebelot/heirline.nvim/commit/7684d4b1147fd929d0fdfe3ecbf2c5706e12f029))
* **winbar:** remove redrawstatus on BufWinEnter: window flicker tradeoff is not worth it ([14d1971](https://github.com/rebelot/heirline.nvim/commit/14d197154c5afdbbcea7de1560d0ecd5df464304))


### Performance Improvements

* **buflist:** add cache to buf_func ([ad52add](https://github.com/rebelot/heirline.nvim/commit/ad52add8afe8b17979ab30c83c122685c443c5ed))
* **clear_tree:** simplify for loop ([6ce8e76](https://github.com/rebelot/heirline.nvim/commit/6ce8e762a079fe0614955feccf146273625bbad9))
* **cookbook:** document StatusLine base methods ([c96f77b](https://github.com/rebelot/heirline.nvim/commit/c96f77b5ebe26a11c4d458b7d187f2bd46c8a9e9))
* **cookbook:** ViMode ([0b93d18](https://github.com/rebelot/heirline.nvim/commit/0b93d183b9a4fd9b2b33f9b431753de979da94d0))
* **flexible:** optimize priority sorting in group_flexible_components. ([e881103](https://github.com/rebelot/heirline.nvim/commit/e881103a126524de33c3c8071fee03b77e0e732a))
* **highlights:** improve highlight normalization; privatize highlight functions; add module-level get_highlights() function ([0c91862](https://github.com/rebelot/heirline.nvim/commit/0c918621c56682700163695d20e5415e5754d92d))
* **init:** remove unnecessary global statusline handle initialization ([1aba13f](https://github.com/rebelot/heirline.nvim/commit/1aba13f5620dd8dcff3fac098c75539782fa66d9))
* **init:** set statusline/winbar using vim.o; fix(timeit) ([385df36](https://github.com/rebelot/heirline.nvim/commit/385df36610bffb305b57cea5b5dd819202196b67))
* **navic:** hardcode bitmask ([9af77c2](https://github.com/rebelot/heirline.nvim/commit/9af77c2531a8e10abebf45817e675ecd1966db02))
* **on_colorscheme:** improve on_colorscheme ([1f181fb](https://github.com/rebelot/heirline.nvim/commit/1f181fb62ff54a74d9721806881c224fdf4a3554))
* remove unnecessary else ([ff0e044](https://github.com/rebelot/heirline.nvim/commit/ff0e0443e080094c27f3ac43ce5c9b70eba882c7))
* **timeit:** improve timeit function ([510950a](https://github.com/rebelot/heirline.nvim/commit/510950a437fb5195c85786ca7aab822c63bd2782))
* **utils:** localize some api functions ([60cb8e5](https://github.com/rebelot/heirline.nvim/commit/60cb8e596708278db1c6e98fa48291db2aa2ebd1))
* various performance improvements ([5b72a6a](https://github.com/rebelot/heirline.nvim/commit/5b72a6a612707ada7ae71c4e8985e2148331cfe9))


### Documentation

* **cookbook:** add documentation for new functionality + minor upgrades. ([002eefd](https://github.com/rebelot/heirline.nvim/commit/002eefda5253de9f906bbc504cf21426dd7e5776))


### Code Refactoring

* **flexible_components:** refactor(flexible_components)!:  ([b8f296e](https://github.com/rebelot/heirline.nvim/commit/b8f296ea181a5136ce3ec331d7ab226e840abc69))
* **statusline:** remove stop_when in favor of the more versatile pick_child. ([7649842](https://github.com/rebelot/heirline.nvim/commit/764984253502cbedff7a9678e54ad6c697bb3688))
* **utils:** prepend '_' to private attributes ([1f3b296](https://github.com/rebelot/heirline.nvim/commit/1f3b2961be60878e04cafc5448643bb811851df4))
