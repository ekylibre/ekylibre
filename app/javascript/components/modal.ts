import {parseHTML} from "lib/parseHtml";
import {refresh as behaveRefresh} from "services/behave";
import {delegateListener} from "lib/domEventUtils.ts";
import axios, {AxiosRequestConfig} from "axios";

function modalTemplate(id: string, size: ModalSize) {
    const additionalClass = size === "default" ? '' : `modal-${size}`;

    return `
        <div class="modal fade " id="${id}" role="dialog">
            <div class="modal-dialog modal-dialog-centered ${additionalClass}">
                <div class="modal-content">
                    <div class="modal-header modal-header--document">
                        <button class="close" data-dismiss="modal">
                            <i class="icon icon-destroy"></i>
                        </button>
                        <b class="modal-title"></b>
                    </div>
                    <div class="modal-body" style="max-height: 80vh; overflow: auto">
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

let idSequence = 0;

type ModalSize = 'default' | 'sm' | 'lg';

interface ModalOptions {
    size?: ModalSize
}

const defaultOptions: Required<ModalOptions> = {
    size: 'default'
};

export class Modal {
    private element: Element;
    private titleElement: Element;
    private bodyElement: Element;
    private backdrop: Element;
    private options: Required<ModalOptions>;
    private readonly escListener: EventListenerObject;

    constructor(private title: string, private content: string | Element, options: ModalOptions = {}) {
        this.escListener = new EscListener(this);
        this.options = {...defaultOptions, ...options};
    }

    getBodyElement() {
        return this.bodyElement;
    }

    setBodyString(content: string) {
        this.getBodyElement().innerHTML = content;
        behaveRefresh();
    }

    setTitle(title: string) {
        this.titleElement.textContent = title;
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
        const fragment = parseHTML(modalTemplate(`modal-${idSequence++}`, this.options.size));

        // Safety: We know these elements exist because they are defined in the template returned by `modalTemplate`
        this.element = fragment.firstElementChild!;
        this.titleElement = this.element.querySelector('.modal-title')!;
        this.bodyElement = this.element.querySelector('.modal-body')!;

        document.body.append(this.element);
        delegateListener(this.element, 'click', '[data-dismiss="modal"]', _e => this.close());

        this.show();

        this.titleElement.textContent = this.title;
        this.setBody(this.content);
        this.on('unroll:menu-opened' as any as keyof HTMLElementEventMap, 'input', e => {
            const element = (e as any).detail.unroll.dropDownMenu.get(0);
            if (this.getBodyElement().clientHeight < element.clientHeight){
                const actions: HTMLDivElement = this.getBodyElement().querySelector('.form-actions') as HTMLDivElement
                if(actions){
                    actions.style.marginTop = `${element.clientHeight}px`
                }
            }
        });
        this.on('unroll:menu-closed' as any as keyof HTMLElementEventMap, 'input', e => {
            const actions: HTMLDivElement = this.getBodyElement().querySelector('.form-actions') as HTMLDivElement
            if(actions){
                actions.style.marginTop = ''
            }
        })

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
        window.removeEventListener('keyup', this.escListener);

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

interface ModalOpenRemoteOptions extends ModalOptions {
    containerId?: string,
    title?: string,
    requestConfig?: AxiosRequestConfig
}

export function openRemote(url: string, options: ModalOpenRemoteOptions = {}): Promise<{ modal: Modal, responseText: string }> {
    return axios.get(url, options.requestConfig)
        .then(response => {
            const {title = ''} = options;
            const modal = new Modal(title, response.data, options);
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
