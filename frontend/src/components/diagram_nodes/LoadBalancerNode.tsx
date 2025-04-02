import { memo } from 'react';
import { Handle, NodeProps, Position } from 'reactflow';

// Simple Load Balancer icon SVG
const LoadBalancerIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    width="24"
    height="24"
    fill="none"
    stroke="#c0caf5"
    strokeWidth="1.5"
  >
    <path d="M12 2 L12 6" /> {/* Vertical line down */}
    <path d="M4 6 L20 6" /> {/* Horizontal bar */}
    <path d="M8 6 L8 10" /> {/* Left branch */}
    <path d="M16 6 L16 10" /> {/* Right branch */}
    <circle cx="8" cy="12" r="2" /> {/* Left circle */}
    <circle cx="16" cy="12" r="2" /> {/* Right circle */}
  </svg>
);

const LoadBalancerNode = ({ data }: NodeProps) => {
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
      <LoadBalancerIcon />
      <div style={{ marginLeft: '8px' }}>{data.label}</div>
      <Handle
        type="source"
        position={Position.Bottom}
        style={{ background: 'transparent', border: '1px solid #555' }}
      />
    </div>
  );
};

export default memo(LoadBalancerNode);
