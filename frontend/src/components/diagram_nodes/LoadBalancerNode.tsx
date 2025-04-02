import { memo } from 'react';
import { Handle, NodeProps, Position } from 'reactflow';

// AWS ELB icon SVG - Using stroke
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
    {/* Switched back to stroke for clarity */}
    {/* Simplified AWS ELB Icon Path Data */}
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      d="M12 2a10 10 0 100 20 10 10 0 000-20zm-1 14.5v-3H8v-3h3v-3h2v3h3v3h-3v3h-2zm1-11.5a2.5 2.5 0 100 5 2.5 2.5 0 000-5z"
    />
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
        border: '1px solid #7aa2f7',
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
