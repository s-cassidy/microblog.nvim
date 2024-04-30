# microblog.nvim

Simple plugin for posting to a [micro.blog](https://micro.blog)-hosted blog.

## Dependencies

`microblog.nvim` has depends on two neovim plugins and an external dependency, all of which you probably already have. These are the plugins `telescope.nvim` and `plenary.nvim`, and the CLI tool `curl`.

## Installation

Install in the usual way using your plugin manager, for example

**Lazy**

```lua
{
's-cassidy/microblog.nvim'
    dependencies = {
        'nvim-telescope/telescope.nvim',
        'nvim-lua/plenary.nvim'
}
```

## Configuration

You will need an API key from micro.blog. Go to [account settings](https://micro.blog/account) and scroll to App Tokens near the bottom.

microblog.nvim loads this key from a shell environment variable. By default this is `MB_API_KEY`, but you can change it.

You must pass an array `blogs`, where each entry is a table with fields `url` and `uid`. Your `uid` is _probably_ your blog's `https://something.micro.blog` address. Your `url` may be the same, or it may be your custom domain name.

**Example**

```lua
{
    api_key_variable = "MB_API_KEY",
    blogs = {
        {
            url = "https://mysuperblog1.com",
            uid = "https://mysuperblog1.micro.blog"
        },
        {
            url = "https://mysuperblog2.micro.blog",
            uid = "https://mysuperblog2.micro.blog"
        }
    }
}
```

Pass this `opts` table to `require('microblog').setup()` or use your plugin manager.

Note that `microblog.nvim` does not set any keymaps by default.

## Usage

`microblog.nvim` exposes 4 functions to the user that are also available as commands.

### `pick_post()` or `MicroBlogPickPost`

Requests a list of posts from the server, and allows you to choose a post to edit using `telescope`. The mappings are `<CR>` to select, `q` or `<ESC>` to abort. If you have more than one blog configured, you will first be asked which blog to load the posts from.

Once selected, the post will be opened in a new buffer ready for editing.

### `push_post()` or `MicroBlogPushPost`

This command is used to send your post back to the server and publish it on your blog. You will be asked to set some options such as a title (optional, naturally). Then you will be asked to set some categories for the post if they're enabled on your blog, again using `telescope`. Use `<tab>` to toggle categories on and off, and then hit `<CR>` to confirm the selection.

If you are editing an existing post you selected with `pick_post` or you have already successfully used `push_post` on this buffer, most of these options will have defaults already set, and the result will be to update the post. Alternatively, if you are in a buffer that you haven't already posted before, the result will be a new post.

### `display_post_status()` or `MicroBlogDisplayStatus`

If your buffer has been posted to the server already using `push_post`, or else loaded from the server using `pick_post`, you can use `display_post_status` to check some details about the post such as its title, url, and categories it belongs to.

### `reset_post_status()` or `MicroBlogResetStatus`

This will clear all the post metadata associated with the current buffer. Using `push_post` after using `reset_post_status` will be as if you're making a brand new post, even if you originally opened the buffer using `pick_post`.

## Future plans and contributing

The next feature I would like to implement is a proper `telescope` previewer for `pick_post`. Another nice feature would be automatically inserting the html for uploaded images. I'm open to PRs on both of these things.

I don't intend to add any features relating to following other users, reading other posts, or uploading photos. This is plugin is purely for writing and editing text posts, because neovim is a _text editor_.
