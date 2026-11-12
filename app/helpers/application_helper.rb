module ApplicationHelper
  def field_classes
    "mt-1.5 block w-full rounded-lg border-0 bg-white px-3 py-2.5 text-stone-900 shadow-sm ring-1 ring-stone-300 placeholder:text-stone-400 " \
      "focus:ring-2 focus:ring-navy-600 focus:outline-none dark:bg-white/5 dark:text-white dark:ring-white/15 dark:focus:ring-gold-400"
  end

  def primary_button_classes
    "w-full cursor-pointer rounded-lg bg-navy-800 px-4 py-2.5 font-medium text-white shadow-sm hover:bg-navy-700 " \
      "dark:bg-gold-400 dark:text-navy-950 dark:hover:bg-gold-300"
  end

  def auth_card(title:, subtitle: nil, &block)
    render layout: "layouts/auth_card", locals: { title: title, subtitle: subtitle }, &block
  end
end
