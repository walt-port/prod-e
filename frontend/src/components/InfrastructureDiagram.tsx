import React, { useCallback } from 'react';
import ReactFlow, {
  addEdge,
  Background,
  Connection,
  Controls,
  Edge,
  MarkerType,
  Node,
  useEdgesState,
  useNodesState,
} from 'reactflow';

import 'reactflow/dist/style.css';

// --- Node Definitions ---
const initialNodes: Node[] = [
  {
    id: 'internet',
    position: { x: 100, y: 50 },
    data: { label: 'Internet / User' },
    // Optional: Specify source/target position if needed later
    // sourcePosition: Position.Bottom,
    style: {
      background: '#1f2335',
      color: '#c0caf5',
      border: '1px solid #9ece6a',
      fontFamily: 'Hermit, monospace',
    },
  },
  {
    id: 'alb',
    position: { x: 100, y: 150 },
    data: { label: 'Application Load Balancer' },
    style: {
      background: '#1f2335',
      color: '#c0caf5',
      border: '1px solid #9ece6a',
      fontFamily: 'Hermit, monospace',
    },
  },
  {
    id: 'ecs-service',
    position: { x: 100, y: 250 },
    data: { label: 'ECS Service (prod-e)' },
    style: {
      background: '#1f2335',
      color: '#c0caf5',
      border: '1px solid #9ece6a',
      fontFamily: 'Hermit, monospace',
    },
  },
  {
    id: 'task-1',
    position: { x: 0, y: 350 }, // Relative to service? Adjust later if grouping
    data: { label: 'ECS Task 1' },
    style: {
      background: '#1f2335',
      color: '#c0caf5',
      border: '1px solid #9ece6a',
      fontFamily: 'Hermit, monospace',
      fontSize: '0.8rem',
    },
  },
  {
    id: 'task-2',
    position: { x: 200, y: 350 },
    data: { label: 'ECS Task 2' },
    style: {
      background: '#1f2335',
      color: '#c0caf5',
      border: '1px solid #9ece6a',
      fontFamily: 'Hermit, monospace',
      fontSize: '0.8rem',
    },
  },
  {
    id: 'rds',
    position: { x: 100, y: 450 },
    data: { label: 'RDS Database' },
    // targetPosition: Position.Top,
    style: {
      background: '#1f2335',
      color: '#c0caf5',
      border: '1px solid #9ece6a',
      fontFamily: 'Hermit, monospace',
    },
  },
];

// --- Edge Definitions ---
const initialEdges: Edge[] = [
  {
    id: 'e-internet-alb',
    source: 'internet',
    target: 'alb',
    markerEnd: { type: MarkerType.ArrowClosed, color: '#7aa2f7' },
    style: { stroke: '#7aa2f7' },
    animated: true,
  },
  {
    id: 'e-alb-ecs',
    source: 'alb',
    target: 'ecs-service',
    markerEnd: { type: MarkerType.ArrowClosed, color: '#7aa2f7' },
    style: { stroke: '#7aa2f7' },
    animated: true,
  },
  {
    id: 'e-ecs-task1',
    source: 'ecs-service',
    target: 'task-1',
    markerEnd: { type: MarkerType.ArrowClosed, color: '#7aa2f7' },
    style: { stroke: '#7aa2f7' },
    animated: true,
  },
  {
    id: 'e-ecs-task2',
    source: 'ecs-service',
    target: 'task-2',
    markerEnd: { type: MarkerType.ArrowClosed, color: '#7aa2f7' },
    style: { stroke: '#7aa2f7' },
    animated: true,
  },
  {
    id: 'e-task1-rds',
    source: 'task-1',
    target: 'rds',
    markerEnd: { type: MarkerType.ArrowClosed, color: '#bb9af7' }, // Different color for DB traffic?
    style: { stroke: '#bb9af7' },
    animated: true,
  },
  {
    id: 'e-task2-rds',
    source: 'task-2',
    target: 'rds',
    markerEnd: { type: MarkerType.ArrowClosed, color: '#bb9af7' },
    style: { stroke: '#bb9af7' },
    animated: true,
  },
];

const InfrastructureDiagram: React.FC = () => {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

  // Handler for edge connections (optional for now)
  const onConnect = useCallback(
    (params: Connection | Edge) => setEdges(eds => addEdge(params, eds)),
    [setEdges]
  );

  return (
    <div style={{ width: '100%', height: '100%' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        fitView // Zoom to fit initially
        // ProOptions could hide attribution if needed later
        // proOptions={{ hideAttribution: true }}
      >
        <Controls />
        <Background color="#414868" gap={16} />
      </ReactFlow>
    </div>
  );
};

export default InfrastructureDiagram;
