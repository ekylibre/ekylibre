export type Function1<T> = (e: T) => void;
export type DomeEventListener = Function1<Event>;

export function onElementDetected(selector: string, callback: Function1<HTMLElement>) {
    onDomReady((_e) => {
        const element = document.getElementById(selector);
        if (element !== null) {
            callback(element);
        }
    });
}

export function onDomReady(callback: DomeEventListener) {
    document.addEventListener('turbolinks:load', callback);
}

/**
 * http://youmightnotneedjquery.com/#delegate
 *
 * @param element
 * @param eventName
 * @param selector
 * @param callback
 */
export function delegateListener<K extends keyof HTMLElementEventMap>(
    element: Element,
    eventName: K,
    selector: string,
    callback: (ev: HTMLElementEventMap[K]) => any
) {
    element.addEventListener(
        eventName,
        function (e) {
            // loop parent nodes from the target to the delegation node
            for (let target = e.target as Element; target && target != this; target = (target as Element).parentNode as Element) {
                if (target.matches(selector)) {
                    callback(e as any);
                    break;
                }
            }
        },
        false
    );
}
