
/*
	Custom caption function to have a caption title and body
	author: laurmaedje
	url: https://sitandr.github.io/typst-examples-book/book/snippets/chapters/outlines.html#long-and-short-captions-for-the-outline
*/
#let show-title = state("show-short-title", true)

#let title-caption(title, caption) = (
  context if show-title.get() {
    title
  } else {
    caption
  }
)

#let todo(todo_text) = text(
  fill: red,
  size: 20pt,
  todo_text + "\n\n",
)
