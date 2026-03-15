type StatCardProps = {
  label: string;
  value: string;
};

export function StatCard({ label, value }: StatCardProps) {
  return (
    <article className="statCard">
      <span>{label}</span>
      <strong>{value}</strong>
    </article>
  );
}

