module ApplicationHelper
  def field_classes
    "mt-1.5 block w-full border border-neutral-300 bg-white px-3 py-2 text-neutral-950 placeholder:text-neutral-400 " \
      "focus:border-accent-600 focus:ring-1 focus:ring-accent-600 focus:outline-none " \
      "dark:border-neutral-700 dark:bg-neutral-950 dark:text-white dark:focus:border-accent-400 dark:focus:ring-accent-400"
  end

  def primary_button_classes
    "w-full cursor-pointer bg-neutral-950 px-4 py-2.5 font-medium text-white hover:bg-neutral-800 " \
      "dark:bg-white dark:text-neutral-950 dark:hover:bg-neutral-200"
  end

  def auth_card(title:, subtitle: nil, &block)
    render layout: "layouts/auth_card", locals: { title: title, subtitle: subtitle }, &block
  end
end
