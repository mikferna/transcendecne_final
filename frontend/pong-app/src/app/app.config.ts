import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app-routing.module';

export const appConfig: ApplicationConfig = {
  providers: [provideRouter(routes)]  // Aquí proporcionamos las rutas
};
