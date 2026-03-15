import { MapContainer, Marker, Popup, TileLayer } from 'react-leaflet';
import L from 'leaflet';

const availableIcon = L.divIcon({ className: 'driver driver-available' });
const busyIcon = L.divIcon({ className: 'driver driver-busy' });

const sampleDrivers = [
  { id: 'd1', lat: -19.585, lng: -65.75, status: 'available' },
  { id: 'd2', lat: -19.578, lng: -65.76, status: 'busy' },
];

export function LiveMap() {
  return (
    <MapContainer center={[-19.5836, -65.7531]} zoom={13} className="map">
      <TileLayer url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
      {sampleDrivers.map((driver) => (
        <Marker
          key={driver.id}
          position={[driver.lat, driver.lng]}
          icon={driver.status === 'available' ? availableIcon : busyIcon}
        >
          <Popup>{driver.id}</Popup>
        </Marker>
      ))}
    </MapContainer>
  );
}

