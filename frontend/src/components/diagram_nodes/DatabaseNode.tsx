import { memo } from 'react';
import { Handle, NodeProps, Position } from 'reactflow';

// PostgreSQL elephant icon SVG - Using stroke
const DatabaseIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    width="24"
    height="24"
    fill="none"
    stroke="#c0caf5"
    strokeWidth="1.5"
  >
    {/* Simplified PostgreSQL Elephant Path Data */}
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm3.5 14c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm-7 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm-2.69-4.45c-.3-.2-.51-.53-.51-.91V10c0-.38.21-.71.51-.91l5.19-3.19c.3-.2.69-.2.99 0l5.19 3.19c.3.2.51.53.51.91v.64c0 .38-.21.71-.51.91l-5.19 3.19c-.3.2-.69.2-.99 0l-5.19-3.19z"
    />
  </svg>
);

const DatabaseNode = ({ data }: NodeProps) => {
  return (
    <div
      style={{
        background: '#1f2335',
        color: '#c0caf5',
        fontFamily: 'Hermit, monospace',
        fontSize: '0.75rem',
        padding: '5px 10px',
        borderRadius: '4px',
        display: 'flex',
        alignItems: 'center',
        border: '1px solid #bb9af7',
      }}
    >
      <Handle
        type="target"
        position={Position.Top}
        style={{ background: 'transparent', border: '1px solid #555' }}
      />
      <DatabaseIcon />
      <div style={{ marginLeft: '8px' }}>{data.label}</div>
      {/* No source handle for the database node */}
      <Handle
        type="target" // Keep target handle for connections from services
        position={Position.Left} // Example: Position on the left
        id="a" // Unique ID if multiple handles on the same side
        style={{ background: 'transparent', border: '1px solid #555', top: '50%' }}
      />
    </div>
  );
};

export default memo(DatabaseNode);
