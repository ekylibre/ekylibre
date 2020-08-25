type Selector = string | ((e: Element) => Array<Element>);

function resolveElements(root: Element, selector: Selector): Array<Element> {
    if (typeof selector === 'string') {
        return Array.from(root.querySelectorAll(selector));
    } else {
        return selector(root);
    }
}

class Behavior {
    constructor(private element: HTMLElement, private selector: Selector, private handler: (item: any) => any, private sequence: number) {}

    refresh() {
        resolveElements(this.element, this.selector).forEach((e) => {
            const key = `alreadyBound${this.sequence}`;

            if (!e.hasAttribute(key)) {
                e.setAttribute(key, '1');
                this.handler.call(e);
            }
        });
    }
}

const behaviors: Behavior[] = [];
let sequence = 0;

export function register(element: HTMLElement, selector: string, handler: (item: any) => any) {
    const b = new Behavior(element, selector, handler, sequence++);
    behaviors.push(b);
    b.refresh();
}

export function refresh() {
    behaviors.forEach((b) => b.refresh());
}
