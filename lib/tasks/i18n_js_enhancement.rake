Rake::Task["i18n:js:export"].enhance do
  `yarn prettier --write #{Rails.root.join('app/javascript/services/i18n/translations.json')}`
end
