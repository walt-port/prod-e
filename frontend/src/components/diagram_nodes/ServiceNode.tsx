import { memo } from 'react';
import { Handle, NodeProps, Position } from 'reactflow';

// Placeholder SVG icon data (e.g., simple boxes)
const ServiceIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    width="24"
    height="24"
    fill="none"
    stroke="#c0caf5"
    strokeWidth="1.5"
  >
    <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
    <rect x="7" y="7" width="10" height="10" rx="1" ry="1"></rect>
  </svg>
);

const ServiceNode = ({ data }: NodeProps) => {
  return (
    <div
      style={{
        background: '#1f2335',
        color: '#c0caf5',
        fontFamily: 'Hermit, monospace',
        fontSize: '0.75rem', // Slightly smaller for icon room
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
      <ServiceIcon />
      <div style={{ marginLeft: '8px' }}>{data.label}</div>
      <Handle
        type="source"
        position={Position.Bottom}
        style={{ background: 'transparent', border: '1px solid #555' }}
      />
      {/* Add Left/Right handles if needed for horizontal connections later */}
      {/* <Handle type="target" position={Position.Left} style={{ background: '#555' }} /> */}
      {/* <Handle type="source" position={Position.Right} style={{ background: '#555' }} /> */}
    </div>
  );
};

export default memo(ServiceNode); // Use memo for performance
