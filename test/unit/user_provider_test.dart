
import 'package:flutter_test/flutter_test.dart';
import 'package:mukadam_bi/mukadan/authentication/userProvider.dart';



void main(){
  group("user provider tests", (){
    late UserProvider userProvider;
    setUp((){
      userProvider=UserProvider();
    });

    test("initial user should be null", (){
      expect(userProvider.user, isNull);
    });

    test("notifies listeners when user is set", (){
      bool notified=false;
      userProvider.addListener(()=>notified=true);

      userProvider.loadSavedUser();
      expect(userProvider.user, isNull);
    });

  });
}