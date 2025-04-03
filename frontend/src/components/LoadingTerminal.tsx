import React, { useEffect, useRef, useState } from 'react';

interface LoadingTerminalProps {
  typingSpeed?: number; // Milliseconds per character
  delayBeforeStart?: number; // Milliseconds before typing starts
  onFinished?: () => void;
}

const LoadingTerminal: React.FC<LoadingTerminalProps> = ({
  typingSpeed = 180,
  delayBeforeStart = 500,
  onFinished,
}) => {
  const commands = ['cd /.dev/prod-e', 'exec prod-e']; // Define commands
  const [lines, setLines] = useState<string[]>(['', '']); // State for text of each command line
  const [currentLineIndex, setCurrentLineIndex] = useState(0); // 0 or 1
  const [currentPrompt, setCurrentPrompt] = useState('❯ ~'); // Initial prompt with space
  const [showCursor, setShowCursor] = useState(true);
  const [isFadingOut, setIsFadingOut] = useState(false); // <<< Add fade state

  // Refs for timer IDs
  const startTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const typingIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const startFadeTimeoutRef = useRef<NodeJS.Timeout | null>(null); // <<< Ref for fade start delay
  const finishTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const isFinishingRef = useRef<boolean>(false); // Tracks if final finish logic started

  useEffect(() => {
    isFinishingRef.current = false;
    let localCurrentLineIndex = 0; // Track internal index

    const cleanup = () => {
      if (startTimeoutRef.current) clearTimeout(startTimeoutRef.current);
      if (typingIntervalRef.current) clearInterval(typingIntervalRef.current);
      if (startFadeTimeoutRef.current) clearTimeout(startFadeTimeoutRef.current); // <<< Clear new ref
      if (finishTimeoutRef.current) clearTimeout(finishTimeoutRef.current);
    };
    cleanup();

    // Function to type a single line
    const typeLine = (lineIndex: number) => {
      let charIndex = 0;
      const currentCommand = commands[lineIndex];

      typingIntervalRef.current = setInterval(() => {
        setLines(prevLines => {
          const currentLineText = prevLines[lineIndex];

          // <<< Remove logging for line 1 >>>
          /*
          if (lineIndex === 1) {
            console.log(
              `Tick for line ${lineIndex}: `,
              `currentLength: ${currentLineText.length}, `,
              `currentText: "${currentLineText}"`
            );
          }
          */
          // <<< End logging >>>

          // Check if finished typing the current line
          if (currentLineText.length >= currentCommand.length) {
            clearInterval(typingIntervalRef.current); // Stop typing this line

            // --- Transition to next step ---
            if (lineIndex === 0) {
              // Finished first command
              setCurrentLineIndex(1); // Allow rendering of next prompt/line
              setCurrentPrompt('❯ ~/.dev/prod-e'); // Update prompt immediately

              // <<< Explicitly reset line 1 text before scheduling next typing >>>
              setLines(prevLines => {
                const newLines = [...prevLines];
                newLines[1] = ''; // Ensure line 1 is empty
                return newLines;
              });

              // Schedule typing for the *next* line after a delay
              startTimeoutRef.current = setTimeout(() => typeLine(1), 750);
            } else if (lineIndex === 1) {
              // Finished second (last) command
              if (!isFinishingRef.current) {
                isFinishingRef.current = true;
                setShowCursor(false);
                // Delay starting the fade
                const enterDelay = 200; // ms
                const fadeDuration = 500; // ms
                startFadeTimeoutRef.current = setTimeout(() => {
                  setIsFadingOut(true); // Start fading
                  // Schedule the final onFinished after the fade completes
                  finishTimeoutRef.current = setTimeout(() => {
                    if (onFinished) onFinished();
                  }, fadeDuration);
                }, enterDelay);
              }
            }
            return prevLines; // Return unchanged lines state
          }
          // --- End Transition ---

          // Type next character for the current line
          const nextLineText = currentCommand.substring(0, currentLineText.length + 1);
          const newLines = [...prevLines];
          newLines[lineIndex] = nextLineText;
          return newLines;
        });
      }, typingSpeed);
    };

    // Start typing the first line (index 0) after the initial delay
    startTimeoutRef.current = setTimeout(() => typeLine(0), delayBeforeStart);

    return cleanup; // Cleanup on unmount
  }, [typingSpeed, delayBeforeStart, onFinished]);

  return (
    <div
      className={`bg-[#1a1b26] border border-[#bb9af7]
                 font-mono text-[#c0caf5] outline-none z-50 p-4
                 transition-opacity duration-500 ease-in-out
                 ${isFadingOut ? 'opacity-0' : 'opacity-100'}`}
      style={{
        position: 'fixed',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
        overflow: 'hidden',
        borderRadius: '0.5rem',
        width: '420px',
        minHeight: '200px',
      }}
    >
      {/* Line 1: Initial Prompt */}
      <div className="mb-1">
        <span className="text-[#bb9af7]">❯ ~</span> {/* Added space */}
      </div>
      {/* Line 2: First Command */}
      <div className="mb-1">
        <span className="text-[#bb9af7]">❯</span>
        <span className="ml-2 whitespace-pre">{lines[0]}</span>
        {currentLineIndex === 0 && showCursor && (
          <span
            className="ml-1 inline-block w-2 h-4 bg-[#c0caf5] animate-pulse align-middle"
            style={{ animationDuration: '1s' }}
          ></span>
        )}
      </div>
      {/* Line 3: Changed Prompt (appears after first command) */}
      {currentLineIndex >= 1 && (
        <div className="mb-1">
          <span className="text-[#bb9af7]">{currentPrompt}</span>
        </div>
      )}
      {/* Line 4: Second Command (appears after first command) */}
      {currentLineIndex >= 1 && (
        <div>
          <span className="text-[#bb9af7]">❯</span>
          <span className="ml-2 whitespace-pre">{lines[1]}</span>
          {currentLineIndex === 1 && showCursor && (
            <span
              className="ml-1 inline-block w-2 h-4 bg-[#c0caf5] animate-pulse align-middle"
              style={{ animationDuration: '1s' }}
            ></span>
          )}
        </div>
      )}
    </div>
  );
};

export default LoadingTerminal;
