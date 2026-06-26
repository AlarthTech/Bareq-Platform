import { getHubUrl } from '../../../core/config/env';
import { TOKEN_KEY } from '../../../core/constants';
import type { BookingStatusChangedPayload, NotificationDTO } from '../types';

export type NotificationHandler = (notification: NotificationDTO, unreadCount: number) => void;
export type BookingStatusHandler = (payload: BookingStatusChangedPayload) => void;

export type RealtimeCallbacks = {
  onNotification?: NotificationHandler;
  onBookingStatusChanged?: BookingStatusHandler;
};

export type HubConnectionState = 'disconnected' | 'connecting' | 'connected' | 'failed';

let connectionModule: typeof import('@microsoft/signalr') | null = null;

async function loadSignalR() {
  if (!connectionModule) {
    connectionModule = await import('@microsoft/signalr');
  }
  return connectionModule;
}

/**
 * Singleton SignalR client for admin real-time notifications and booking updates.
 * Connects after login; disconnects on logout.
 */
class NotificationRealtimeService {
  private connection: import('@microsoft/signalr').HubConnection | null = null;
  private callbacks = new Set<RealtimeCallbacks>();
  private stateListeners = new Set<(state: HubConnectionState) => void>();
  private currentState: HubConnectionState = 'disconnected';
  private connectPromise: Promise<void> | null = null;

  subscribe(callbacks: RealtimeCallbacks): () => void {
    this.callbacks.add(callbacks);
    void this.ensureConnected();
    return () => {
      this.callbacks.delete(callbacks);
      if (this.callbacks.size === 0) {
        void this.disconnect();
      }
    };
  }

  subscribeState(listener: (state: HubConnectionState) => void): () => void {
    this.stateListeners.add(listener);
    listener(this.currentState);
    return () => {
      this.stateListeners.delete(listener);
    };
  }

  getState(): HubConnectionState {
    return this.currentState;
  }

  private setState(state: HubConnectionState) {
    this.currentState = state;
    this.stateListeners.forEach((l) => l(state));
  }

  private emitNotification(notification: NotificationDTO, unreadCount: number) {
    this.callbacks.forEach((cb) => cb.onNotification?.(notification, unreadCount));
  }

  private emitBookingStatusChanged(payload: BookingStatusChangedPayload) {
    this.callbacks.forEach((cb) => cb.onBookingStatusChanged?.(payload));
  }

  async ensureConnected(): Promise<void> {
    const token = localStorage.getItem(TOKEN_KEY);
    if (!token) return;

    if (this.connection?.state === 'Connected') return;

    if (this.connectPromise) {
      await this.connectPromise;
      return;
    }

    this.connectPromise = this.connect();
    try {
      await this.connectPromise;
    } finally {
      this.connectPromise = null;
    }
  }

  async reconnectIfNeeded(): Promise<void> {
    const token = localStorage.getItem(TOKEN_KEY);
    if (!token || this.callbacks.size === 0) return;

    const signalR = await loadSignalR();
    if (
      !this.connection ||
      this.connection.state === signalR.HubConnectionState.Disconnected
    ) {
      await this.connect();
    }
  }

  async reconnectWithFreshToken(): Promise<void> {
    await this.connect();
  }

  private registerHandlers() {
    if (!this.connection) return;

    this.connection.off('ReceiveNotification');
    this.connection.off('BookingStatusChanged');

    this.connection.on(
      'ReceiveNotification',
      (notification: NotificationDTO, unreadCount: number) => {
        this.emitNotification(notification, unreadCount);
      }
    );

    this.connection.on('BookingStatusChanged', (payload: BookingStatusChangedPayload) => {
      this.emitBookingStatusChanged(payload);
    });
  }

  async connect(): Promise<void> {
    const token = localStorage.getItem(TOKEN_KEY);
    if (!token) return;

    await this.disconnectInternal(false);

    this.setState('connecting');

    try {
      const signalR = await loadSignalR();
      const hubUrl = `${getHubUrl()}?access_token=${encodeURIComponent(token)}`;

      this.connection = new signalR.HubConnectionBuilder()
        .withUrl(hubUrl, { withCredentials: true })
        .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
        .configureLogging(signalR.LogLevel.Warning)
        .build();

      this.registerHandlers();

      this.connection.onreconnected(() => {
        this.setState('connected');
      });

      this.connection.onclose(() => {
        if (this.currentState !== 'connecting') {
          this.setState('disconnected');
        }
      });

      await this.connection.start();
      this.setState('connected');
    } catch {
      this.connection = null;
      this.setState('failed');
    }
  }

  async disconnect(): Promise<void> {
    await this.disconnectInternal(true);
  }

  private async disconnectInternal(clearCallbacks: boolean) {
    if (this.connection) {
      try {
        await this.connection.stop();
      } catch {
        /* ignore */
      }
      this.connection = null;
    }
    this.setState('disconnected');
    if (clearCallbacks) {
      this.callbacks.clear();
    }
  }
}

export const notificationRealtimeService = new NotificationRealtimeService();

/** @deprecated Use notificationRealtimeService */
export const notificationHubManager = {
  setHandler: (handler: NotificationHandler | null) => {
    if (!handler) return () => undefined;
    return notificationRealtimeService.subscribe({ onNotification: handler });
  },
  subscribeState: (listener: (state: HubConnectionState) => void) =>
    notificationRealtimeService.subscribeState(listener),
  connect: () => notificationRealtimeService.ensureConnected(),
  disconnect: () => notificationRealtimeService.disconnect(),
  reconnectWithFreshToken: () => notificationRealtimeService.reconnectWithFreshToken(),
  getState: () => notificationRealtimeService.getState(),
};
