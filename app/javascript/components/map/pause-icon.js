import L from 'leaflet';
import iconRetinaUrl from './marker-images/pause-icon-2x.png';
import iconUrl from './marker-images/pause-icon.png';

L.Icon.Pause = L.Icon.Default.extend({
    options: {
        iconUrl,
        iconRetinaUrl,
    },
});
