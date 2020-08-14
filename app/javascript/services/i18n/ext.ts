import I18n from "i18n-js";


function sliceMonthList(key: string) {
    const translation = I18n.translate(key);
    if (Object.prototype.toString.call(translation) === '[object Array]') {
        return translation.slice(1, 13);
    }
}

/*
    Remove list element if element has his value equal to :
     - null
     - undefined
     - NaN
     - empty string
     - 0
     - false
*/
function cleanArray(list: Array<any>) {
    return list.filter(function (n) {
        if (n) {
            return true;
        } else {
            return false;
        }
    });
}


class Dates {

    getDayNames() {
        return I18n.translate('date.day_names');
    }

    getMonthNames() {
        return sliceMonthList('date.month_names');
    }

    getAbbrDayNames() {
        return I18n.translate('date.abbr_day_names');
    }

    getAbbrMonthNames() {
        return sliceMonthList('date.abbr_month_names');
    }

    getOrder() {
        return I18n.translate('date.order');
    }
}


class DateFormat {

    default() {
        return I18n.translate('date.formats.default');
    }

    legal() {
        return I18n.translate('date.formats.legal');
    }

    short() {
        return I18n.translate('date.formats.short');
    }

    long() {
        return I18n.translate('date.formats.long');
    }

    month() {
        return I18n.translate('date.formats.month');
    }

    monthLetter() {
        return I18n.translate('date.formats.month_letter');
    }
}


class Datetime {

    am() {
        return I18n.translate('time.am');
    }

    pm() {
        return I18n.translate('time.pm');
    }

    periods() {
        return [this.am(), this.pm()];
    }
}


class DatetimeFormat {

    default() {
        return I18n.translate('time.formats.default');
    }

    long() {
        return I18n.translate('time.formats.long');
    }

    short() {
        return I18n.translate('time.formats.short');
    }

    time() {
        return I18n.translate('time.formats.time');
    }

    full() {
        return I18n.translate('time.formats.full');
    }

    fullJsFormat() {
        return I18n.translate('time.js_formats.full');
    }
}

export const ext = {
    dates: new Dates(),
    dateFormat: new DateFormat(),
    datetime: new Datetime(),
    datetimeFormat: new DatetimeFormat()
}