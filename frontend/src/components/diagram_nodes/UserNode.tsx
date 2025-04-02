import { memo } from 'react';
import { Handle, NodeProps, Position } from 'reactflow';

// Cloud icon SVG
const UserIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    width="24"
    height="24"
    fill="none"
    stroke="#c0caf5"
    strokeWidth="1.5"
  >
    <path d="M18 10h-1.26A8 8 0 1 0 4 16.14" />
    <path d="M16 16.14A8 8 0 0 0 18 10h-1.26" /> {/* Corrected path for cloud shape */}
  </svg>
);

const UserNode = ({ data }: NodeProps) => {
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
      {/* No target handle for the ultimate source */}
      <UserIcon />
      <div style={{ marginLeft: '8px' }}>{data.label}</div>
      <Handle
        type="source"
        position={Position.Bottom}
        style={{ background: 'transparent', border: '1px solid #555' }}
      />
    </div>
  );
};

export default memo(UserNode);
