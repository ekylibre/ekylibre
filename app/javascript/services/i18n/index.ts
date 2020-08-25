import I18n from 'i18n-js';
import translations from './translations.json';
import { ext } from './ext';

const ISO3_LANG_KEY = 'data-lang-iso3';
const DEFAULT_LANGUAGE = 'fra';

function getLocaleFromDocument(): string {
    const element = document.firstElementChild;
    if (element && element.hasAttribute(ISO3_LANG_KEY)) {
        // Safety: We just checked above that the element has the attribute
        return element.getAttribute(ISO3_LANG_KEY)!;
    } else {
        return DEFAULT_LANGUAGE;
    }
}

I18n.defaultLocale = getLocaleFromDocument();
I18n.locale = I18n.defaultLocale;
I18n.translations = translations;
(I18n as any).ext = ext;

export { I18n };
export const translate = I18n.translate.bind(I18n);
