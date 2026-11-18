module CommentsHelper
  VOTE_ICONS = {
    up: "M10 4.5a.75.75 0 0 1 .55.24l4.75 5.25a.75.75 0 0 1-.55 1.26H12v4a.75.75 0 0 1-.75.75h-2.5A.75.75 0 0 1 8 15.25v-4H5.25a.75.75 0 0 1-.55-1.26l4.75-5.25A.75.75 0 0 1 10 4.5Z",
    down: "M10 15.5a.75.75 0 0 1-.55-.24L4.7 10.01a.75.75 0 0 1 .55-1.26H8v-4A.75.75 0 0 1 8.75 4h2.5a.75.75 0 0 1 .75.75v4h2.75a.75.75 0 0 1 .55 1.26l-4.75 5.25a.75.75 0 0 1-.55.24Z"
  }.freeze

  # Clicking the arrow you already chose takes your vote back.
  def vote_button(comment, direction, vote)
    active = vote&.direction == direction.to_s
    label = active ? "Remove your #{direction}vote" : "#{direction.to_s.capitalize}vote"

    button_to decision_comment_vote_path(comment.decision, comment),
      method: active ? :delete : :put, params: active ? {} : { direction: direction },
      form: { class: "contents", data: { turbo_frame: "_top" } },
      data: { ownership_target: "vote" }, aria: { label: label, pressed: active }, title: label,
      class: "cursor-pointer rounded p-0.5 text-neutral-400 transition-colors duration-150 hover:bg-neutral-100 hover:text-neutral-950 " \
        "disabled:cursor-default disabled:opacity-40 disabled:hover:bg-transparent disabled:hover:text-neutral-400 " \
        "aria-pressed:text-accent-600 dark:hover:bg-neutral-800 dark:hover:text-white dark:aria-pressed:text-accent-400" do
      tag.svg(tag.path(d: VOTE_ICONS.fetch(direction)), class: "size-4", viewBox: "0 0 20 20", fill: "currentColor", aria: { hidden: true })
    end
  end
end
