module ApplicationHelper
  def field_classes
    "mt-1.5 block w-full rounded-lg border border-neutral-300 bg-white px-3 py-2 text-neutral-950 placeholder:text-neutral-400 " \
      "transition-shadow duration-150 focus:border-accent-500 focus:ring-4 focus:ring-accent-500/15 focus:outline-none " \
      "dark:border-neutral-700 dark:bg-neutral-950 dark:text-white dark:focus:border-accent-400 dark:focus:ring-accent-400/20"
  end

  def primary_button_classes
    "w-full cursor-pointer rounded-lg bg-neutral-950 px-4 py-2.5 font-medium text-white shadow-sm transition-colors duration-150 hover:bg-neutral-800 " \
      "dark:bg-white dark:text-neutral-950 dark:hover:bg-neutral-200"
  end

  AVATAR_CLASSES = [
    "bg-accent-100 text-accent-700 dark:bg-accent-500/20 dark:text-accent-200",
    "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-200",
    "bg-amber-100 text-amber-800 dark:bg-amber-500/20 dark:text-amber-200",
    "bg-rose-100 text-rose-700 dark:bg-rose-500/20 dark:text-rose-200",
    "bg-violet-100 text-violet-700 dark:bg-violet-500/20 dark:text-violet-200",
    "bg-teal-100 text-teal-700 dark:bg-teal-500/20 dark:text-teal-200"
  ].freeze

  def avatar_classes(user)
    AVATAR_CLASSES[user.id.to_i % AVATAR_CLASSES.size]
  end

  def auth_card(title:, subtitle: nil, &block)
    render layout: "layouts/auth_card", locals: { title: title, subtitle: subtitle }, &block
  end
end
