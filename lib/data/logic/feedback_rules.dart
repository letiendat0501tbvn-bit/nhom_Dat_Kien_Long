// Quy tắc cho phản hồi riêng tư (hàm thuần, dễ test).

const maxFeedbackLength = 500;

// Hợp lệ: không rỗng/toàn khoảng trắng và tối đa 500 ký tự.
bool isValidFeedback(String text) =>
    text.trim().isNotEmpty && text.length <= maxFeedbackLength;
