import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main(List<String> arguments) async {
  //Будем искать вот такой сертификат
  const certificateNumber = 'ЕАЭС RU С-BD.АД61.В.00150/20';

  //Строка запроса поиска сертификатов по критериям:
  const requestString =
      '{"size":10,"page":0,"filter":{"regDate":{"minDate":"","maxDate":""},"endDate":{"minDate":"","maxDate":""},"columnsSearch":[{"column":"number","search":"$certificateNumber"}]},"columnsSort":[{"column":"date","sort":"DESC"}]}';

  const host = 'https://pub.fsa.gov.ru';
  const loginGate = '/login';
  const accountGate = '/lk/api/account';
  const identifiersGate = '/api/v1/rss/common/identifiers';
  const username = 'anonymous';
  const password = 'hrgesf7HDR67Bd';

  const getSSGate = '/api/v1/rss/common/certificates';

  const certificatesReferer = 'https://pub.fsa.gov.ru/rss/certificate';

  const referer = certificatesReferer;
  const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0';

  const loginGateHeader = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'ru,en-US;q=0.8,en;q=0.5,zh-CN;q=0.3',
    'Connection': 'keep-alive',
    'lkId': '',
    'orgId': '',
    'Referer': referer,
    'User-Agent': userAgent,
    'Host': 'pub.fsa.gov.ru',
    'Authorization': 'Bearer null',
    'Content-Length': '52',
    'Content-Type': 'application/json',
    'Origin': 'https://pub.fsa.gov.ru',
  };

  HttpOverrides.global = MyHttpOverrides();

  var loginResponse = await http.post('$host$loginGate',
      body: convert.jsonEncode({'username': username, 'password': password}),
      headers: loginGateHeader);

  var bearerToken = loginResponse.headers['authorization'];

  var accountGateHeader = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'ru,en-US;q=0.8,en;q=0.5,zh-CN;q=0.3',
    'Connection': 'keep-alive',
    'lkId': '',
    'orgId': '',
    'Referer': referer,
    'User-Agent': userAgent,
    'Host': 'pub.fsa.gov.ru',
    'Authorization': bearerToken,
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  var accountResponse =
      await http.get('$host$accountGate', headers: accountGateHeader);
  var accountCookie = accountResponse.headers['set-cookie'];

  var identifiersGateHeader = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'ru,en-US;q=0.8,en;q=0.5,zh-CN;q=0.3',
    'Connection': 'keep-alive',
    'lkId': '',
    'orgId': '',
    'Referer': referer,
    'User-Agent': userAgent,
    'Host': 'pub.fsa.gov.ru',
    'Authorization': bearerToken,
    'Cache-Control': 'no-cache',
    'Cookie': accountCookie,
    'Pragma': 'no-cache',
  };

  var identifiersResponse =
      await http.get('$host$identifiersGate', headers: identifiersGateHeader);
  var identifiersCookie = identifiersResponse.headers['set-cookie'];

  var getSSGateBody = requestString;

  // dart работает с UTF-16, а нам нужна длина строки запроса в UTF8
  var contentLength = convert.utf8.encode(getSSGateBody).length.toString();

  var getSSGateHeader = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'ru,en-US;q=0.8,en;q=0.5,zh-CN;q=0.3',
    'Connection': 'keep-alive',
    'lkId': '',
    'orgId': '',
    'Referer': referer,
    'User-Agent': userAgent,
    'Host': 'pub.fsa.gov.ru',
    'Authorization': bearerToken,
    'Cache-Control': 'no-cache',
    'Content-Length': contentLength,
    'Content-Type': 'application/json',
    'Cookie': identifiersCookie,
    'Origin': 'https://pub.fsa.gov.ru',
    'Pragma': 'no-cache',
  };

  var getSSResponse = await http.post('$host$getSSGate/get',
      headers: getSSGateHeader, body: getSSGateBody);

  var getSScookie = getSSResponse.headers['set-cookie'];

  //в теле ответа, в зависимости от критериев поиска, будут данные по сертификатам(ту).

  //Коды поля "idStatus":
  // 14 - прекращён
  // 6 - действует
  // 5 - выдано предписание
  // 1 - архивный

  //например общая информация по сертификату
  var items = (convert.jsonDecode(getSSResponse.body))['items'][0];

  //статус сертификата
  var certificateStatus = items['idStatus'];
  print('Статус сертификата: $certificateStatus');

  //id сертификата в системе
  var certificateId = items['id'];

  //Полная информация по сертификату
  var getSSDataHeader = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'ru,en-US;q=0.8,en;q=0.5,zh-CN;q=0.3',
    'Connection': 'keep-alive',
    'lkId': '',
    'orgId': '',
    'Referer': referer,
    'User-Agent': userAgent,
    'Host': 'pub.fsa.gov.ru',
    'Authorization': bearerToken,
    'Cache-Control': 'no-cache',
    'Cookie': getSScookie,
    'Pragma': 'no-cache',
  };

  var getCertificateDataResponse = await http
      .get('$host$getSSGate/$certificateId', headers: getSSDataHeader);

  var certificateData = getCertificateDataResponse.body;
  print('Данные по сертификату:');
  print(certificateData);
}
