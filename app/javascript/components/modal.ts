import {parseHTML} from "lib/parseHtml";
import {refresh as behaveRefresh} from "services/behave";
import {delegateListener} from "lib/domEventUtils.ts";
import axios from "axios";

function modalTemplate(id: string) {
    return `
        <div class="modal fade" id="${id}" role="dialog">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header modal-header--document">
                        <button class="close" data-dismiss="modal">
                            <i class="icon icon-destroy"></i>
                        </button>
                        <b class="modal-title"></b>
                    </div>
                    <div class="modal-body">
                    </div>
                </div>
            </div>
        </div>
    `;
}

class EscListener {
    constructor(private modal: Modal) {
    }

    handleEvent(e: Event) {
        if (e instanceof KeyboardEvent && e.key === 'Escape') {
            this.modal.close();
        }
    }
}

interface ModalOptions {
    title?: string
}

let idSequence = 0;

export class Modal {
    private element: Element;
    private titleElement: Element;
    private bodyElement: Element;
    private backdrop: Element;
    private readonly escListener: EventListenerObject;

    constructor(private title: string, private content: string | Element) {
        this.escListener = new EscListener(this);
    }

    getBodyElement() {
        return this.bodyElement;
    }

    setBodyString(content: string) {
        this.getBodyElement().innerHTML = content;
        behaveRefresh();
    }

    setBody(content: Element | string) {
        if (content instanceof Element) {
            this.getBodyElement().innerHTML = '';
            this.getBodyElement().appendChild(content);
            behaveRefresh();
        } else {
            this.setBodyString(content);
        }
    }

    open() {
        const fragment = parseHTML(modalTemplate(`modal-${idSequence++}`));

        // Safety: We know these elements exist because they are defined in the template returned by `modalTemplate`
        this.element = fragment.firstElementChild!;
        this.titleElement = this.element.querySelector('.modal-title')!;
        this.bodyElement = this.element.querySelector('.modal-body')!;

        document.body.append(this.element);
        delegateListener(this.element, 'click', '[data-dismiss="modal"]', _e => this.close());

        this.titleElement.textContent = this.title;
        this.setBody(this.content);

        this.show();
    }

    on<K extends keyof HTMLElementEventMap>(eventName: K, selector: string, callback: (this: HTMLElement, ev: HTMLElementEventMap[K]) => any) {
        delegateListener(this.element, eventName, selector, callback);
    }

    close() {
        this.hide();
        this.element.remove();
    }

    show() {
        this.addBackdrop();
        this.element.classList.add('in');
        this.element.setAttribute('style', 'display: block;');
        this.element.addEventListener('click', e => {
            if (e.target === this.element) {
                this.close();
            }
        });
        window.addEventListener('keyup', this.escListener);
    }

    hide() {
        this.element.classList.add('out');
        this.element.classList.remove('in');
        this.element.setAttribute('style', 'display: none;');
        this.removeBackdrop();
    }

    private addBackdrop() {
        this.backdrop = document.createElement('div');
        this.backdrop.classList.add('modal-backdrop', 'fade', 'in');

        document.body.append(this.backdrop);
    }

    private removeBackdrop() {
        this.backdrop.remove();
    }
}

export function openRemote(url: string, options: ModalOptions = {}): Promise<{ modal: Modal, responseText: string }> {
    return axios.get(this.url)
        .then(response => {
            const {title = ''} = options;
            const modal = new Modal(title, response.data);
            modal.open();

            return {modal, responseText: response.data};
        });
}

export function openFromElementDataAttributes(element: Element) {
    const title = element.getAttribute('data-modal-title') || "";
    const body = element.getAttribute('data-modal-body') || "";

    return open(title, body);
}

export function open(title: string, body: string) {
    const modal = new Modal(title, body);
    modal.open();

    return modal;
}
