/// Contract for the Groq chat-completions backend.
abstract interface class AiCoachDatasource {
  /// Sends [prompt] with the user's [context] and returns the raw model reply.
  Future<String> callGroqApi(String prompt, String context);
}
