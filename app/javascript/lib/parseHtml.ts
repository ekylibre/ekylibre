export function parseHTML(html: string): DocumentFragment {
    const template = document.createElement('template');
    template.innerHTML = html.trim();

    return template.content;
}
