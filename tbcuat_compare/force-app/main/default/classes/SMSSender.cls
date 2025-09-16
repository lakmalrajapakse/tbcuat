public class SMSSender {
    public static void sendSMS(String to, String body) {
        SMSSenderService senderService = new SMSSenderService();
        senderService.sendSMS(to, body);
    }
}