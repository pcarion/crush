# Crush User Prompt Handling - Sequence Diagram

## Overview
This diagram illustrates how Crush handles a user prompt from input to response display.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant Editor as Editor<br/>(TUI Component)
    participant ChatPage as Chat Page<br/>(TUI)
    participant Session as Session<br/>Service
    participant Agent as Coder Agent
    participant Provider as LLM Provider<br/>(OpenAI/Anthropic)
    participant DB as Database<br/>(SQLite)
    participant PubSub as PubSub<br/>Broker
    participant Messages as Messages<br/>(UI Component)
    participant Tools as Tools<br/>(bash, edit, etc)

    User->>Editor: Types prompt & presses Enter
    Editor->>Editor: send() creates SendMsg
    Editor->>ChatPage: chat.SendMsg{text, attachments}
    
    alt New conversation
        ChatPage->>Session: CreateSession()
        Session->>DB: Insert session
        Session-->>ChatPage: session ID
    end
    
    ChatPage->>ChatPage: sendMessage()
    ChatPage->>Agent: Run(ctx, sessionID, prompt)
    
    Agent->>DB: CreateUserMessage()
    DB-->>Agent: message ID
    
    par Async title generation
        Agent->>Agent: generateTitle()
        Agent->>Provider: Generate title
        Provider-->>Agent: title
        Agent->>Session: UpdateTitle()
    end
    
    Agent->>Agent: streamAndHandleEvents()
    Agent->>Provider: StreamResponse(messages)
    
    loop Streaming response
        Provider-->>Agent: Event (ContentDelta/ToolUse/Complete)
        
        alt Content Delta
            Agent->>Agent: processEvent(ContentDelta)
            Agent->>DB: UpdateMessage(content)
            DB->>PubSub: Publish(UpdatedEvent, message)
            PubSub->>Messages: pubsub.Event[message]
            Messages->>Messages: Update display
            Messages-->>User: Show streaming text
        else Tool Use
            Agent->>Agent: processEvent(ToolUseStart)
            Agent->>Tools: Execute tool
            Tools-->>Agent: Tool result
            Agent->>DB: UpdateMessage(toolResult)
            DB->>PubSub: Publish(UpdatedEvent, message)
            PubSub->>Messages: pubsub.Event[message]
            Messages->>Messages: Update display
            Messages-->>User: Show tool execution
        else Complete
            Agent->>Agent: processEvent(Complete)
            Agent->>DB: FinalizeMessage()
            DB->>PubSub: Publish(UpdatedEvent, message)
            PubSub->>Messages: pubsub.Event[message]
            Messages->>Messages: Final render
            Messages-->>User: Show complete response
        end
    end
    
    Agent-->>ChatPage: Return (success/error)
    ChatPage->>ChatPage: Update UI state
```

## Key Components

### 1. **User Input Layer**
- **Editor Component**: Handles text input, file attachments, and keyboard shortcuts
- **Chat Page**: Manages the overall chat interface and session state

### 2. **Business Logic Layer**
- **Session Service**: Manages conversation sessions and persistence
- **Coder Agent**: Orchestrates LLM interactions, tool execution, and response handling
- **LLM Provider**: Abstraction layer supporting multiple providers (OpenAI, Anthropic, Gemini, etc.)

### 3. **Data Layer**
- **Database (SQLite)**: Persists messages, sessions, and file history
- **PubSub Broker**: Enables real-time event broadcasting across components

### 4. **Presentation Layer**
- **Messages Component**: Renders messages with syntax highlighting, animations, and tool outputs
- **TUI Framework**: Bubble Tea framework for reactive terminal UI updates

### 5. **Tool Execution**
- **Tools Package**: Implements various tools (bash, file operations, search, etc.)
- **Permission System**: Manages tool execution permissions and user confirmations

## Event Flow Details

### Message Creation & Storage
1. User message is immediately stored in database with `role: "user"`
2. Assistant message is created with `role: "assistant"` and empty content
3. Content is streamed and appended to the assistant message

### Real-time Updates via PubSub
- Every database update triggers a PubSub event
- UI components subscribe to relevant events
- Updates are rendered immediately without polling

### Tool Execution Flow
1. LLM requests tool use with parameters
2. Agent validates and executes tool
3. Tool results are stored and sent back to LLM
4. LLM incorporates results into response

### Error Handling
- Network errors trigger retry logic in providers
- Tool errors are captured and sent to LLM for recovery
- UI shows error states with appropriate messaging

## File References
- Main entry: `main.go`, `internal/cmd/root.go`
- Editor: `internal/tui/components/chat/editor/editor.go`
- Chat Page: `internal/tui/page/chat/chat.go`
- Agent: `internal/llm/agent/agent.go`
- Providers: `internal/llm/provider/*.go`
- Database: `internal/db/*.go`
- PubSub: `internal/pubsub/broker.go`
- Messages UI: `internal/tui/components/chat/messages/messages.go`
- Tools: `internal/llm/tools/*.go`