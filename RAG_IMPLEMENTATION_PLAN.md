# RAG (Retrieval-Augmented Generation) Implementation Plan

## Overview
This plan outlines the implementation of RAG (Retrieval-Augmented Generation) and long-term memory for the BuyOrNot AI chatbot. The system will remember past conversations, user preferences, and decision patterns to provide more personalized and context-aware advice.

## Goals
1. **Long-term Memory**: Store and retrieve past conversations and user decisions
2. **Context Retrieval**: Retrieve relevant past conversations when making new decisions
3. **Personalized Advice**: Use historical data to provide better purchase recommendations
4. **Pattern Recognition**: Learn from user's past decisions (what they bought, skipped, why)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     User Input                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              RAG Service (New Component)                     │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │  Embedding       │  │  Vector Search   │                │
│  │  Generator       │  │  & Retrieval     │                │
│  └──────────────────┘  └──────────────────┘                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Firestore (Vector Store)                        │
│  - Conversation Embeddings                                  │
│  - Decision History                                          │
│  - User Preferences                                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Enhanced Context                                │
│  - Current Message                                           │
│  - Retrieved Past Conversations                             │
│  - User Decision Patterns                                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Google Gemini API                               │
│  (With Enhanced Context)                                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Response + Storage                              │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Strategy

### Phase 1: Data Model & Storage (Week 1)

#### 1.1 Extend Firestore Schema
**File**: `FirebaseDataManager.swift`

Add new collections:
- `conversations/{conversationId}`: Store full conversations
  - `decisionId`: UUID (link to decision)
  - `messages`: Array of messages
  - `summary`: String (conversation summary)
  - `embeddings`: Array of Float (vector embeddings)
  - `timestamp`: Timestamp
  - `userId`: String

- `userPreferences/{userId}`: Store user patterns
  - `preferredCategories`: Array of strings
  - `averagePriceRange`: Object {min, max}
  - `decisionPatterns`: Object (bought vs skipped ratios)
  - `lastUpdated`: Timestamp

- `conversationEmbeddings/{conversationId}`: Vector store
  - `embedding`: Array of Float (1536 dimensions for text-embedding-004)
  - `metadata`: Object (decisionId, userId, timestamp, summary)
  - `text`: String (full conversation text for retrieval)

#### 1.2 Update Data Models
**File**: `chatmessage.swift` (already exists)

Add:
- `conversationId`: UUID? (link conversations)
- `embedding`: [Float]? (cached embedding)

**New File**: `ConversationEmbedding.swift`
```swift
struct ConversationEmbedding: Codable, Identifiable {
    let id: UUID
    let decisionId: UUID
    let userId: String
    let embedding: [Float]
    let text: String
    let summary: String
    let timestamp: Date
}
```

### Phase 2: Embedding Generation (Week 1-2)

#### 2.1 Choose Embedding Model
**Option A: Google's text-embedding-004 (Recommended)**
- Free tier: 1,500 requests/minute
- 768 dimensions
- API: `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent`

**Option B: Vertex AI Embeddings**
- More features, requires Vertex AI setup
- Better for enterprise scale

**Option C: OpenAI text-embedding-3-small**
- 1536 dimensions
- Requires OpenAI API key
- Good quality, paid service

**Decision**: Use Google's `text-embedding-004` for consistency with existing Gemini API usage.

#### 2.2 Create Embedding Service
**New File**: `EmbeddingService.swift`

```swift
import Foundation

class EmbeddingService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // Generate embedding for text
    func generateEmbedding(for text: String) async throws -> [Float] {
        // Implementation details in Phase 2
    }
    
    // Generate embedding for conversation
    func generateConversationEmbedding(messages: [ChatMessage]) async throws -> [Float] {
        // Combine messages into single text
        let conversationText = messages.map { "\($0.role): \($0.text)" }.joined(separator: "\n")
        return try await generateEmbedding(for: conversationText)
    }
}
```

### Phase 3: Vector Search & Retrieval (Week 2)

#### 3.1 Vector Search Strategy

**Option A: Firestore Native (Simple but Limited)**
- Store embeddings as arrays in Firestore
- Use cosine similarity calculation in Swift
- Query all documents, calculate similarity, sort
- **Pros**: No additional services, simple
- **Cons**: Slow for large datasets, expensive queries

**Option B: Vertex AI Vector Search (Recommended for Scale)**
- Managed vector database
- Fast similarity search
- **Pros**: Scalable, fast, managed
- **Cons**: Requires Vertex AI setup, additional cost

**Option C: Pinecone / Weaviate (Third-party)**
- External vector database
- **Pros**: Fast, scalable
- **Cons**: Additional service, cost, complexity

**Decision for MVP**: Start with Option A (Firestore + Swift cosine similarity), migrate to Option B if needed.

#### 3.2 Create Vector Search Service
**New File**: `VectorSearchService.swift`

```swift
import Foundation
import FirebaseFirestore

class VectorSearchService {
    private let db = Firestore.firestore()
    
    // Cosine similarity calculation
    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        // Implementation
    }
    
    // Retrieve similar conversations
    func findSimilarConversations(
        embedding: [Float],
        userId: String,
        limit: Int = 5
    ) async throws -> [ConversationEmbedding] {
        // Query Firestore, calculate similarity, return top results
    }
}
```

### Phase 4: RAG Service Integration (Week 2-3)

#### 4.1 Create RAG Service
**New File**: `RAGService.swift`

```swift
import Foundation

class RAGService {
    private let embeddingService: EmbeddingService
    private let vectorSearchService: VectorSearchService
    private let dataManager: FirebaseDataManager
    
    // Retrieve relevant context for current conversation
    func retrieveContext(
        for decision: Decision,
        currentMessages: [ChatMessage],
        userId: String
    ) async throws -> RAGContext {
        // 1. Generate embedding for current conversation
        // 2. Search for similar past conversations
        // 3. Retrieve user preferences
        // 4. Build context object
    }
    
    // Store conversation with embedding
    func storeConversation(
        decisionId: UUID,
        messages: [ChatMessage],
        userId: String
    ) async throws {
        // 1. Generate embedding
        // 2. Store in Firestore
        // 3. Update user preferences
    }
}

struct RAGContext {
    let relevantConversations: [ConversationEmbedding]
    let userPreferences: UserPreferences?
    let decisionPatterns: DecisionPatterns?
}
```

#### 4.2 Update Chat Service
**File**: `chatbot.swift` - Update `GoogleChatService`

Modify `send` function to:
1. Call `RAGService.retrieveContext()` before sending to Gemini
2. Include retrieved context in the prompt
3. Store conversation after response

### Phase 5: Enhanced Prompting (Week 3)

#### 5.1 Context-Aware Prompts

Update the prompt sent to Gemini to include:
- Retrieved past conversations
- User's decision history
- Preferences and patterns
- Current decision context

Example enhanced prompt structure:
```
You are a personal shopping advisor. Here's what I know about this user:

Past Similar Decisions:
[Retrieved conversations]

User Preferences:
- Average price range: $X - $Y
- Tends to buy: [categories]
- Tends to skip: [categories]

Current Decision:
[Current product and context]

Based on this context, provide personalized advice...
```

### Phase 6: User Preference Learning (Week 3-4)

#### 6.1 Pattern Analysis
**New File**: `PreferenceAnalyzer.swift`

Analyze user decisions to learn:
- Price sensitivity
- Category preferences
- Buy vs skip patterns
- Decision factors (price, need, want)

#### 6.2 Update Preferences
After each decision (buy/skip), update:
- User preferences document
- Decision patterns
- Category preferences

## Implementation Steps

### Step 1: Setup & Dependencies
1. ✅ Verify Google API key has access to `text-embedding-004`
2. Add embedding API endpoint to API key configuration
3. Update Firestore security rules for new collections

### Step 2: Data Models
1. Create `ConversationEmbedding.swift`
2. Create `UserPreferences.swift`
3. Create `DecisionPatterns.swift`
4. Update `FirebaseDataManager.swift` with new CRUD operations

### Step 3: Embedding Service
1. Create `EmbeddingService.swift`
2. Implement `generateEmbedding(for:)` method
3. Test with sample text
4. Add error handling and retry logic

### Step 4: Vector Search
1. Create `VectorSearchService.swift`
2. Implement cosine similarity function
3. Implement Firestore query and similarity calculation
4. Test retrieval with sample embeddings

### Step 5: RAG Service
1. Create `RAGService.swift`
2. Implement `retrieveContext()` method
3. Implement `storeConversation()` method
4. Integrate with existing chat flow

### Step 6: Chat Integration
1. Update `GoogleChatService` to use RAG
2. Modify prompt to include retrieved context
3. Store conversations after each chat
4. Test end-to-end flow

### Step 7: Preference Learning
1. Create `PreferenceAnalyzer.swift`
2. Implement pattern analysis
3. Update preferences after decisions
4. Use preferences in RAG context

### Step 8: Testing & Optimization
1. Test with various scenarios
2. Optimize embedding generation (batch, caching)
3. Optimize vector search (indexing, limits)
4. Monitor API usage and costs

## Technical Details

### Embedding API Call
```swift
POST https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=API_KEY

{
  "model": "models/text-embedding-004",
  "content": {
    "parts": [{"text": "Your conversation text here"}]
  }
}

Response:
{
  "embedding": {
    "values": [0.123, -0.456, ...] // 768 dimensions
  }
}
```

### Cosine Similarity Formula
```swift
func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count else { return 0 }
    
    let dotProduct = zip(a, b).map(*).reduce(0, +)
    let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
    
    return dotProduct / (magnitudeA * magnitudeB)
}
```

### Firestore Query Strategy
1. Query all conversation embeddings for user (with limit)
2. Calculate cosine similarity in Swift
3. Sort by similarity
4. Return top N results

**Optimization**: Add timestamp filter to only search recent conversations (e.g., last 6 months).

## Cost Considerations

### Google Embedding API
- Free tier: 1,500 requests/minute
- Pricing: Check current Google AI pricing
- Estimated: ~$0.0001 per embedding (768 dimensions)

### Firestore
- Storage: ~1KB per conversation embedding
- Reads: 1 read per search (if querying all)
- Writes: 1 write per conversation stored

**Optimization**: Cache embeddings, batch operations, limit search scope.

## Security & Privacy

1. **Data Isolation**: Ensure embeddings are user-specific (query by userId)
2. **Data Retention**: Implement retention policy (delete old conversations)
3. **Privacy**: Don't include sensitive information in embeddings
4. **Access Control**: Firestore rules to restrict access

## Future Enhancements

1. **Semantic Search**: Improve retrieval with better embeddings
2. **Multi-modal RAG**: Include image embeddings for product recognition
3. **Fine-tuning**: Fine-tune Gemini with user-specific data
4. **Real-time Updates**: Update preferences in real-time
5. **A/B Testing**: Test different RAG strategies

## Success Metrics

1. **Relevance**: Retrieved conversations are relevant to current decision
2. **Personalization**: Advice becomes more personalized over time
3. **User Satisfaction**: Users find advice more helpful
4. **Performance**: Response time < 2 seconds
5. **Cost**: API costs remain reasonable

## Timeline

- **Week 1**: Data models, embedding service, basic storage
- **Week 2**: Vector search, RAG service integration
- **Week 3**: Enhanced prompting, preference learning
- **Week 4**: Testing, optimization, polish

## Next Steps

1. Review and approve this plan
2. Set up Google Embedding API access
3. Create initial data models
4. Begin Phase 1 implementation

