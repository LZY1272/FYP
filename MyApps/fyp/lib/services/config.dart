final url = 'http://172.22.7.171:3000/';
final registration = "${url}registration";
final login = "${url}login";
final addtodo = "${url}storeTodo";
final getTodoList = "${url}getUserTodoList";
final deleteTodo = "${url}deleteTodo";
final saveItinerary = "${url}saveItinerary";
final deleteItinerary = "${url}deleteItinerary";
final updateItinerary = "${url}updateItinerary";
String getItinerary(String userId) {
  return "${url}getUserItineraries/$userId";
}
