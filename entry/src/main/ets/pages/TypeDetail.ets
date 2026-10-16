import { PokemonDataSource } from '../data/DataSource';
import { DamageRelations, TypeInfo } from '../Model/Type';
import { HttpErrorComponent, LoadComponent } from './Index';

interface RouterParams {
  url: string;
  typeName: string;
}

@Entry
@Component
struct TypeDetail {
  @State url: string = '';
  @State typeName: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State damageRelation: DamageRelations = new DamageRelations();

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as RouterParams;
    if (!params || !params.url) {
      this.errorMessage = 'This type could not be opened. Return to a Pokémon and try again.';
      return;
    }
    this.url = params.url;
    this.typeName = params.typeName || '';
    this.loadType();
  }

  private async loadType(): Promise<void> {
    if (this.url.length === 0) {
      this.errorMessage = 'This type could not be opened. Return to a Pokémon and try again.';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const source = new PokemonDataSource();
      this.damageRelation = await source.getTypeDetail(this.url);
    } catch (error) {
      console.error('Failed to load type:', error);
      this.errorMessage = 'Could not load type relations. Check your connection and try again.';
    } finally {
      this.isLoading = false;
    }
  }

  @Builder
  Header() {
    Row() {
      Text('Type')
        .fontSize(26)
        .fontWeight(800)
        .fontColor('#0F0026')
        .layoutWeight(1);
      Image($r('app.media.home_icon'))
        .width(28)
        .height(28)
        .focusable(true)
        .accessibilityText('Home')
        .onClick(() => {
          this.getUIContext().getRouter().clear();
          this.getUIContext().getRouter().pushUrl({ url: 'pages/Index' });
        });
    }
    .width('100%')
    .padding({ top: 12, bottom: 8 });
  }

  @Builder
  TypeItem(item: TypeInfo) {
    Text(item.name)
      .fontSize(14)
      .fontWeight(700)
      .fontColor('#6024B5')
      .padding({ left: 14, right: 14, top: 9, bottom: 9 })
      .backgroundColor('#F8F3FF')
      .borderRadius(12)
      .margin({ right: 8 })
      .onClick(() => {
        this.getUIContext().getRouter().replaceUrl({
          url: 'pages/TypeDetail',
          params: { url: item.url, typeName: item.name }
        });
      });
  }

  @Builder
  RelationSection(label: string, items: TypeInfo[]) {
    Column({ space: 10 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(600)
        .fontColor('#0F0026');
      if (items.length === 0) {
        Text('None')
          .fontSize(14)
          .fontColor('#5E5470');
      } else {
        List() {
          ForEach(items, (item: TypeInfo) => {
            ListItem() {
              this.TypeItem(item);
            }
          }, (item: TypeInfo) => item.url);
        }
        .listDirection(Axis.Horizontal)
        .height(42);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16);
  }

  build() {
    Column({ space: 12 }) {
      this.Header();
      if (this.isLoading) {
        LoadComponent({ label: 'Loading type relations…' });
      } else if (this.errorMessage.length > 0) {
        HttpErrorComponent({ text: this.errorMessage });
        if (this.url.length > 0) {
          Button('Retry')
            .backgroundColor('#6024B5')
            .onClick(() => this.loadType());
        }
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Text(this.typeName)
              .fontWeight(800)
              .fontSize(30)
              .fontColor('#0F0026')
              .width('100%')
              .padding(20)
              .backgroundColor('#FFFFFF')
              .borderRadius(18);

            Text('Attack')
              .fontWeight(700)
              .fontSize(20)
              .fontColor('#0F0026')
              .margin({ top: 8 });
            this.RelationSection(`${this.typeName} moves are super effective against:`,
              this.damageRelation.double_damage_to);
            this.RelationSection(`${this.typeName} moves are not very effective against:`,
              this.damageRelation.half_damage_to);
            this.RelationSection(`${this.typeName} moves have no effect against:`,
              this.damageRelation.no_damage_to);

            Text('Defense')
              .fontWeight(700)
              .fontSize(20)
              .fontColor('#0F0026')
              .margin({ top: 8 });
            this.RelationSection(`These types are not very effective against ${this.typeName}:`,
              this.damageRelation.half_damage_from);
            this.RelationSection(`These types are super effective against ${this.typeName}:`,
              this.damageRelation.double_damage_from);
            this.RelationSection(`These types have no effect against ${this.typeName}:`,
              this.damageRelation.no_damage_from);
          }
          .width('100%')
          .padding({ bottom: 24 })
          .alignItems(HorizontalAlign.Start);
        }
        .layoutWeight(1);
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F8F3FF');
  }
}
