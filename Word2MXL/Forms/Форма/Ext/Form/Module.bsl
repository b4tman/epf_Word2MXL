﻿&НаКлиенте
Асинх Процедура Конвертировать(Команда)
	Диалог = Новый ПараметрыДиалогаПомещенияФайлов;
	Диалог.Заголовок = "Выберите документ";
	Диалог.МножественныйВыбор = Ложь;
	Диалог.Фильтр = "Документы (*.doc,*.docx,*.rtf)|*.doc;*.docx;*.rtf|Все файлы|*.*";
	
	Прогресс = 0;
	Элементы.ГруппаПрогресс.Видимость = Истина;
	Элементы.Прогресс.Видимость = Истина;
	Состояние = "Передача файла";
	Оповещение_ОХодеВыполнения = Новый ОписаниеОповещения("ПомещениеФайла_ОповещенияОХодеВыполнения", ЭтаФорма, Неопределено);
	ОписаниеФайла = Ждать ПоместитьФайлНаСерверАсинх(Оповещение_ОХодеВыполнения, , , Диалог, ЭтаФорма.УникальныйИдентификатор);
	
	Элементы.Прогресс.Видимость = Ложь;
	Прогресс = 0;
	
	Если Неопределено = ОписаниеФайла Тогда
		Элементы.ГруппаПрогресс.Видимость = Ложь;
		Возврат;
	КонецЕсли;
	
	Состояние = "Конвертация";
	ОбновитьОтображениеДанных(Элементы.Состояние);
	КонвертироватьНаСервере(ОписаниеФайла.Адрес, ОписаниеФайла.СсылкаНаФайл.Расширение);
	Элементы.ГруппаПрогресс.Видимость = Ложь;
	Элементы.СтраницаРезультат.Видимость = Истина;
	Элементы.ГруппаСтраницы.ТекущаяСтраница = Элементы.СтраницаРезультат;
КонецПроцедуры

&НаКлиенте
Процедура ПомещениеФайла_ОповещенияОХодеВыполнения(ПомещаемыйФайл, Помещено, ОтказОтПомещенияФайла, ДополнительныеПараметры) Экспорт
	Прогресс = Помещено;
КонецПроцедуры

&НаКлиентеНаСервереБезКонтекста
Процедура ПопыткаУдалитьФайлы(Файлы)
	Если Неопределено = Файлы Тогда
		Возврат;
	КонецЕсли;
	
	Попытка
		УдалитьФайлы(Файлы);
	Исключение
	КонецПопытки;
	
	Файлы = Неопределено;
КонецПроцедуры

&НаСервере
Процедура КонвертироватьНаСервере(Знач Адрес, Знач Расширение)
	Обработка = РеквизитФормыВЗначение("Объект");
	
	РезультатКонвертации = Неопределено;
	
	ВремФайл = ПолучитьИмяВременногоФайла(Расширение);
	Данные = ПолучитьИзВременногоХранилища(Адрес);
	Данные.Записать(ВремФайл);
	Данные = Неопределено;
	ИмяФайла = ВремФайл;
	
	Попытка
		РезультатКонвертации = Обработка.ВывестиДокументВордВМоксель(ИмяФайла, рСантиметр, рШиринаСтраницы, ФильтрТаблиц);
	Исключение
		Ошибка = ОписаниеОшибки();
		Причина = ИнформацияОбОшибке();
		
		ПопыткаУдалитьФайлы(ВремФайл);
		Если ЭтоАдресВременногоХранилища(Адрес) Тогда
			УдалитьИзВременногоХранилища(Адрес);
			Адрес = Неопределено;
		КонецЕсли;
		
		ВызватьИсключение("Ошибка конвертации в mxl", КатегорияОшибки.ОшибкаВнешнегоИсточникаДанных, "500", Ошибка, Причина);
	КонецПопытки;
	
	ПопыткаУдалитьФайлы(ВремФайл);
	Если ЭтоАдресВременногоХранилища(Адрес) Тогда
		УдалитьИзВременногоХранилища(Адрес);
		Адрес = Неопределено;
	КонецЕсли;
	
	Если Не Неопределено = РезультатКонвертации Тогда
		ДокументРезультат = РезультатКонвертации;
	КонецЕсли;
	
КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	Элементы.ГруппаПрогресс.Видимость = Ложь;
	Элементы.СтраницаРезультат.Видимость = Ложь;
	ФильтрТаблиц = "Условие = (Элемент.Columns.Count > 1 И Элемент.Rows.Count > 1) ИЛИ Элемент.Rows.Count = 4";
	рСантиметр = 6.25;
	рШиринаСтраницы = 75;
КонецПроцедуры