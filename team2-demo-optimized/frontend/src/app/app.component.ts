import { Component } from '@angular/core';
import { ApiService, HelloResponse } from './api.service';

@Component({
  selector: 'app-root',
  template: `
    <div class="container">
      <h1>Team 2 Demo Frontend</h1>
      <button (click)="callBackend()" [disabled]="loading">
        {{ loading ? 'Loading...' : 'Call Backend' }}
      </button>
      <div *ngIf="response" class="success">
        <strong>Backend says:</strong> {{ response.message }}
      </div>
      <div *ngIf="error" class="error">
        <strong>Error:</strong> {{ error }}
      </div>
    </div>
  `,
  styles: [`
    .container {
      max-width: 600px;
      margin: 50px auto;
      padding: 20px;
      font-family: Arial, sans-serif;
    }
    h1 {
      color: #333;
    }
    button {
      padding: 10px 20px;
      font-size: 16px;
      background-color: #007bff;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      margin: 20px 0;
    }
    button:hover:not(:disabled) {
      background-color: #0056b3;
    }
    button:disabled {
      background-color: #ccc;
      cursor: not-allowed;
    }
    .success {
      padding: 15px;
      background-color: #d4edda;
      border: 1px solid #c3e6cb;
      border-radius: 4px;
      color: #155724;
      margin-top: 20px;
    }
    .error {
      padding: 15px;
      background-color: #f8d7da;
      border: 1px solid #f5c6cb;
      border-radius: 4px;
      color: #721c24;
      margin-top: 20px;
    }
  `]
})
export class AppComponent {
  response?: HelloResponse;
  error?: string;
  loading = false;

  constructor(private api: ApiService) {}

  callBackend(): void {
    this.loading = true;
    this.error = undefined;
    this.response = undefined;

    this.api.getHello().subscribe({
      next: (res) => {
        this.response = res;
        this.loading = false;
      },
      error: (err) => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }
}
