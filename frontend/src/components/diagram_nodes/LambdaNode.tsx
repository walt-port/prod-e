import { Handle, NodeProps, Position } from 'reactflow';

// AWS Lambda icon SVG - Using stroke
const LambdaIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    width="24"
    height="24"
    fill="none"
    stroke="#c0caf5"
    strokeWidth="1.5"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      d="M17.9 4.03l-6.97 6.97-2.93-2.93L4 12l4 4 2.93-2.93 6.97 6.97L22 16V8l-4.1-3.97zM6.07 12.03L2 8l4.07 4.03zM17.9 19.97L22 16l-4.1 3.97z"
    />
  </svg>
);

const LambdaNode = ({ data }: NodeProps) => {
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
        border: '1px solid #7dcfff', // Different border color for Lambda?
      }}
    >
      {/* Target handle (e.g., invoked by App) */}
      <Handle
        type="target"
        position={Position.Left}
        id="a"
        style={{ background: 'transparent', border: '1px solid #555', top: '50%' }}
      />
      <LambdaIcon />
      <div style={{ marginLeft: '8px' }}>{data.label}</div>
      {/* Source handle (e.g., calls AWS services - optional) */}
      {/* <Handle
        type="source"
        position={Position.Right}
        id="b"
        style={{ background: 'transparent', border: '1px solid #555', top: '50%' }}
      /> */}
    </div>
  );
};

export default LambdaNode;
