export function parseHTML(html: String): DocumentFragment {
    const template = document.createElement('template')
    template.innerHTML = html.trim()

    return template.content
}