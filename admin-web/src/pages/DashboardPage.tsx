import { LiveMap } from '../components/LiveMap';
import { StatCard } from '../components/StatCard';

export function DashboardPage() {
  return (
    <main className="layout">
      <section className="hero">
        <div>
          <p className="eyebrow">Taxi Ya / Potosi Operations</p>
          <h1>Live city dispatch for a 15 km service radius.</h1>
        </div>
        <div className="stats">
          <StatCard label="Available drivers" value="128" />
          <StatCard label="Trips in progress" value="36" />
          <StatCard label="Dispatch latency" value="1.8s" />
        </div>
      </section>
      <section className="mapPanel">
        <LiveMap />
      </section>
    </main>
  );
}

