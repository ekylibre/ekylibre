import autocomplete from 'autocompleter';
import { GeocodingService } from 'services/GeocodingService';

export function geocodingInput(element, onSelectCallback = null) {
    const geocodingService = new GeocodingService();

    autocomplete({
        input: element,
        fetch: function (text, update) {
            geocodingService.suggest(text).then((result) => {
                const suggestions = result.map((address) => {
                    return { label: address, value: address };
                });
                update(suggestions);
            });
        },
        onSelect: function (item) {
            element.value = item.label;

            if (typeof onSelectCallback === 'function') {
                onSelectCallback(item.label);
            }
        },
        debounceWaitMs: 500,
        preventSubmit: true,
    });
}
