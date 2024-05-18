# microblog.nvim

Simple plugin for posting to a [micro.blog](https://micro.blog)-hosted blog.

## Dependencies

`microblog.nvim` has depends on two neovim plugins and an external dependency, all of which you probably already have. These are the plugins `telescope.nvim` and `plenary.nvim`, and the CLI tool `curl`.

On Linux use your usual package manager to install `curl`.

On Mac you can do

```
brew install curl
```

## Installation

Install in the usual way using your plugin manager, for example

**Lazy**

```lua
{
    's-cassidy/microblog.nvim',
    dependencies = {
        'nvim-telescope/telescope.nvim',
        'nvim-lua/plenary.nvim'
    }
}
```

## Configuration

You will need an app token from micro.blog. Go to [account settings](https://micro.blog/account) and scroll to App Tokens near the bottom.

microblog.nvim loads this key from a shell environment variable. By default this is `MB_APP_TOKEN`, but you can change it.

You must pass an array `blogs`, where each entry is a table with fields `url` and `uid`. Your `uid` is _probably_ your blog's `https://something.micro.blog` address. Your `url` may be the same, or it may be your custom domain name.

Other options:

- `always_input_url`. If this is set to `true`, you will be given the opportunity to manually edit the url of a post to update whenever you send a post to the server (which you can leave blank to make a new post). If this is left as `false` (recommended), it will just use the existing url attached to the post.
- `no_save_quickpost`. If set to `true`, then using the `quickpost()` function will also set the buffer to a `nowrite` buffer (see below).
- `token_warn_on_startup`. If set to `true`, you'll be alerted if the `MB_APP_TOKEN` is not defined as soon as the plugin loads. If set to `false`, you'll only be alerted if you take an action that requires the app token.

**Example**

```lua
{
    app_token_variable = "MB_APP_TOKEN",
    blogs = {
        {
            url = "https://mysuperblog1.com",
            uid = "https://mysuperblog1.micro.blog"
        },
        {
            url = "https://mysuperblog2.micro.blog",
            uid = "https://mysuperblog2.micro.blog"
        }
    },
    always_input_url = false,
    no_save_quickpost = false,
    token_warn_on_startup = false,
}
```

Pass this `opts` table to `require('microblog').setup()` or use your plugin manager.

Note that `microblog.nvim` does not set any keymaps by default.

## Usage

`microblog.nvim` exposes the following functions to the user

### `pick_post()`

Requests a list of posts from the server, and allows you to choose a post to edit using `telescope`. The mappings are `<CR>` to select, `q` or `<ESC>` to abort. If you have more than one blog configured, you will first be asked which blog to load the posts from.

Once selected, the post will be opened in a new buffer ready for editing.

### `get_post_from_url()`

Opens prompt to input the url of a post. If given a valid url from your blog, it will open in a new buffer read for editing. You can also pass an url as an argument to `MicroBlogPostFromUrl` to open it without a prompt.

### `publish()`

This command is used to send your post back to the server and publish it on your blog. You will be asked to set some options such as a title. Then a `telescope` picker will allow you to select some categories for your post. Use `<tab>` to toggle categories on and off, and then hit `<CR>` to confirm the selection.

If you are editing an existing post or you have already successfully used `publish` on this buffer, most of these options will have defaults already set, and the result will be to update the post. Alternatively, if you are in a buffer that you haven't already posted before, the result will be a new post.

You can also use `publish` in visual mode to post only the selected lines of text.

### `quickpost()`

For quickly dashing off a "micro" post. This will post the current buffer with no title or categories to the **first** blog in your `blogs` list.

If `no_save_quickpost` is set to `true`, this means you can `:q` without saving after running `quickpost()`. In other words, set this option if you don't care about keeping a local copy of your "micro" posts once they have been posted. You can still manually save with `:w <filename>`, if you like.

### `display_post_status()`

If your buffer has been posted to the server already using `push_post`, or else loaded from the server using `pick_post`, you can use `display_post_status` to check some details about the post such as its title, url, and categories it belongs to.

### `reset_post_status()`

This will clear all the post metadata associated with the current buffer. Using `push_post` after using `reset_post_status` will be as if you're making a brand new post, even if you originally opened the buffer using `pick_post`.

## Future plans and contributing

The next feature I would like to implement is a proper `telescope` previewer for `pick_post`. Another nice feature would be automatically inserting the html for uploaded images. I'm open to PRs on both of these things.

I do not currently have plans to support other fuzzy finders such as `mini.fuzzy` or `fzf-lua`. PRs welcome if you want to implement these.

I don't intend to add any features relating to following other users, reading other posts, or uploading photos. This is plugin is purely for publishing text posts, because neovim is a _text editor_.

## Thanks

To [Manton](https://manton.org) for creating micro.blog, [TJ](https://github.com/tjdevries) for creating `telescope` and `plenary`, and [HeyLoura](https://heyloura.com/) (check out her awesome site!) who built [LilliHub](https://lillihub.com/), whose source code provided useful examples of the API.
