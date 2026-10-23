import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../usecase/usecase.dart';
import '../../locale_usecases.dart';
import 'locale_event.dart';
import 'locale_state.dart';

@injectable
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc(this._getLocale, this._setLocale) : super(const LocaleInitial()) {
    on<LoadLocale>(_onLoad);
    on<ChangeLocale>(_onChange);
  }

  final GetLocaleUseCase _getLocale;
  final SetLocaleUseCase _setLocale;

  Future<void> _onLoad(LocaleEvent event, Emitter<LocaleState> emit) async {
    final result = await _getLocale(const NoParams());
    result.fold(
      (failure) => emit(LocaleFailure(failure.message)),
      (locale) => emit(LocaleLoaded(locale)),
    );
  }

  Future<void> _onChange(ChangeLocale event, Emitter<LocaleState> emit) async {
    final result = await _setLocale(event.locale);
    result.fold(
      (failure) => emit(LocaleFailure(failure.message)),
      (locale) => emit(LocaleLoaded(locale)),
    );
  }
}
