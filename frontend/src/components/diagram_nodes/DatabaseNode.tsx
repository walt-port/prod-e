import { memo } from 'react';
import { Handle, NodeProps, Position } from 'reactflow';

// Database cylinder icon SVG
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
    <ellipse cx="12" cy="5" rx="9" ry="3"></ellipse>
    <path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"></path>
    <path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"></path>
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
      }}
    >
      <Handle
        type="target"
        position={Position.Top}
        style={{ background: 'transparent', border: '1px solid #555' }}
      />
      <DatabaseIcon />
      <div style={{ marginLeft: '8px' }}>{data.label}</div>
      {/* No source handle if it's the final destination */}
    </div>
  );
};

export default memo(DatabaseNode);
