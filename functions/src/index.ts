import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
// import cors removed

// Initialize Firebase Admin SDK
admin.initializeApp();

// Initialize Firestore
const db = admin.firestore();
// const corsHandler = undefined;

// Paymob API endpoints
const PAYMOB_AUTH_URL = 'https://accept.paymob.com/api/auth/tokens';
const PAYMOB_ORDER_URL = 'https://accept.paymob.com/api/ecommerce/orders';
const PAYMOB_PAYMENT_KEY_URL = 'https://accept.paymob.com/api/acceptance/payment_keys';

// Paymob config from environment variables
interface PaymobConfig {
  apiKey: string;
  hmac: string;
  merchantId: string;
  integrationIdCard: string;
  integrationIdWallet: string;
}

// Get Paymob config from environment or use placeholders
const getPaymobConfig = (): PaymobConfig => {
  const config = functions.config();
  return {
    apiKey: config?.paymob?.api_key || 'placeholder_api_key',
    hmac: config?.paymob?.hmac || 'placeholder_hmac',
    merchantId: config?.paymob?.merchant_id || 'placeholder_merchant_id',
    integrationIdCard: config?.paymob?.integration_id_card || 'placeholder_integration_id_card',
    integrationIdWallet: config?.paymob?.integration_id_wallet || 'placeholder_integration_id_wallet',
  };
};

// Check if we're using mock mode (no real API keys)
const isUsingMockPaymob = (): boolean => {
  const config = getPaymobConfig();
  return config.apiKey === 'placeholder_api_key';
};

// ---------------------------------------------------------------------------
// AWS S3 helpers
// ---------------------------------------------------------------------------

type AwsConfig = {
  accessKeyId: string;
  secretAccessKey: string;
  region: string;
  bucket: string;
  basePath?: string; // e.g. 'Nor/'
  publicRead?: boolean;
};

const getAwsConfig = (): AwsConfig => {
  const c = functions.config();
  return {
    accessKeyId: c?.aws?.access_key_id || '',
    secretAccessKey: c?.aws?.secret_access_key || '',
    region: c?.aws?.region || 'eu-west-1',
    bucket: c?.aws?.bucket || '',
    basePath: c?.aws?.base_path || 'Nor/',
    publicRead: c?.aws?.public_read === 'true',
  };
};

const getS3Client = (): S3Client => {
  const cfg = getAwsConfig();
  if (!cfg.accessKeyId || !cfg.secretAccessKey || !cfg.bucket) {
    throw new Error(
      'AWS S3 is not configured. Set functions config: aws.access_key_id, aws.secret_access_key, aws.region, aws.bucket, aws.base_path'
    );
  }
  return new S3Client({
    region: cfg.region,
    credentials: {
      accessKeyId: cfg.accessKeyId,
      secretAccessKey: cfg.secretAccessKey,
    },
  });
};

// Types for Paymob API requests/responses
interface PaymobAuthResponse {
  token: string;
}

interface PaymobOrderResponse {
  id: number;
  token: string;
}

interface PaymobPaymentKeyResponse {
  token: string;
}

// Helper function to get Paymob authentication token
const getPaymobAuthToken = async (): Promise<string> => {
  if (isUsingMockPaymob()) {
    return 'mock_auth_token';
  }

  const config = getPaymobConfig();
  const response = await axios.post<PaymobAuthResponse>(PAYMOB_AUTH_URL, {
    api_key: config.apiKey,
  });
  
  return response.data.token;
};

// Helper function to create Paymob order
const createPaymobOrder = async (
  authToken: string, 
  amount: number, 
  orderId: string
): Promise<PaymobOrderResponse> => {
  if (isUsingMockPaymob()) {
    return {
      id: 12345,
      token: 'mock_order_token',
    };
  }

  const config = getPaymobConfig();
  const response = await axios.post<PaymobOrderResponse>(PAYMOB_ORDER_URL, {
    auth_token: authToken,
    delivery_needed: false,
    amount_cents: Math.round(amount * 100),
    currency: 'EGP',
    merchant_order_id: orderId,
    items: [],
  });
  
  return response.data;
};

// Helper function to get Paymob payment key
const getPaymobPaymentKey = async (
  authToken: string, 
  orderId: number, 
  orderToken: string, 
  amount: number, 
  method: string
): Promise<string> => {
  if (isUsingMockPaymob()) {
    return 'mock_payment_key';
  }

  const config = getPaymobConfig();
  
  // Choose integration ID based on payment method
  const integrationId = method === 'card' 
    ? config.integrationIdCard 
    : config.integrationIdWallet;
  
  const response = await axios.post<PaymobPaymentKeyResponse>(PAYMOB_PAYMENT_KEY_URL, {
    auth_token: authToken,
    amount_cents: Math.round(amount * 100),
    expiration: 3600,
    order_id: orderId,
    billing_data: {
      apartment: 'NA',
      email: 'customer@example.com',
      floor: 'NA',
      first_name: 'Nory',
      street: 'NA',
      building: 'NA',
      phone_number: '+201000000000',
      shipping_method: 'NA',
      postal_code: 'NA',
      city: 'Cairo',
      country: 'Egypt',
      last_name: 'Shop',
      state: 'NA',
    },
    currency: 'EGP',
    integration_id: integrationId,
    lock_order_when_paid: false,
  });
  
  return response.data.token;
};

// 1. Create Paymob Payment (HTTPS callable)
export const createPaymobPayment = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to create a payment.'
    );
  }
  
  // We ignore any client-supplied currency and force EGP downstream.
  const { amount, orderId, method } = data;
  
  // Validate inputs
  if (!amount || amount <= 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Amount must be a positive number.'
    );
  }
  
  if (!orderId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Order ID is required.'
    );
  }
  
  if (method !== 'card' && method !== 'wallet') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Payment method must be either "card" or "wallet".'
    );
  }
  
  try {
    // If using mock mode, return mock data
    if (isUsingMockPaymob()) {
      return {
        success: true,
        isMock: true,
        paymentKey: 'mock_payment_key',
        checkoutUrl: `https://accept.paymob.com/api/acceptance/iframes/123?payment_token=mock_payment_key`,
      };
    }
    
    // Get authentication token
    const authToken = await getPaymobAuthToken();
    
    // Create order
    const order = await createPaymobOrder(authToken, amount, orderId);
    
    // Get payment key
    const paymentKey = await getPaymobPaymentKey(
      authToken, 
      order.id, 
      order.token, 
      amount, 
      method
    );
    
    // Generate checkout URL based on payment method
    let checkoutUrl;
    if (method === 'card') {
      // For card payments, use iframe URL
      checkoutUrl = `https://accept.paymob.com/api/acceptance/iframes/123?payment_token=${paymentKey}`;
    } else {
      // For wallet payments, return the payment key (mobile app will handle this)
      checkoutUrl = null;
    }
    
    return {
      success: true,
      isMock: false,
      paymentKey,
      checkoutUrl,
    };
  } catch (error) {
    console.error('Error creating Paymob payment:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create payment. Please try again later.'
    );
  }
});

// ---------------------------------------------------------------------------
// 3. Create S3 Upload URL (HTTPS callable)
// ---------------------------------------------------------------------------

export const createS3UploadUrl = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required.');
  }

  const { fileName, contentType } = data || {};
  if (!fileName || !contentType) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'fileName and contentType are required.'
    );
  }

  try {
    const aws = getAwsConfig();
    const s3 = getS3Client();

    const userPrefix = `${context.auth.uid}/`;
    const ts = Date.now();
    const safeName = String(fileName).replace(/[^a-zA-Z0-9._-]/g, '_');
    const key = `${aws.basePath ?? ''}${userPrefix}${ts}_${safeName}`;

    // PUT presign for upload
    const putCmd = new PutObjectCommand({
      Bucket: aws.bucket,
      Key: key,
      ContentType: contentType,
    });
    const uploadUrl = await getSignedUrl(s3, putCmd, { expiresIn: 900 }); // 15 min

    // GET presign for download (if not public)
    const getCmd = new GetObjectCommand({
      Bucket: aws.bucket,
      Key: key,
    });
    const getUrl = await getSignedUrl(s3, getCmd, { expiresIn: 900 });

    const publicUrl = aws.publicRead
      ? `https://${aws.bucket}.s3.${aws.region}.amazonaws.com/${key}`
      : undefined;

    return {
      success: true,
      key,
      uploadUrl,
      getUrl,
      publicUrl,
    };
  } catch (error) {
    console.error('S3 presign error', error);
    throw new functions.https.HttpsError(
      'internal',
      (error as any).message || 'Failed to create S3 upload URL'
    );
  }
});

// 2. Verify Paymob HMAC (HTTPS callable)
export const verifyPaymobHmac = functions.https.onCall(async (data, context) => {
  // This would typically be called from a webhook or after payment completion
  
  const { hmacPayload } = data;
  
  if (!hmacPayload) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'HMAC payload is required.'
    );
  }
  
  try {
    // In mock mode, always return success
    if (isUsingMockPaymob()) {
      return {
        verified: true,
        isMock: true,
        transactionId: 'mock_transaction_id',
        orderId: data.orderId || 'mock_order_id',
      };
    }
    
    // In a real implementation, we would:
    // 1. Extract the HMAC from the payload
    // 2. Calculate our own HMAC using our secret key
    // 3. Compare the two HMACs
    
    // This is a placeholder for the actual implementation
    const config = getPaymobConfig();
    
    // For demo purposes, we're just checking if the hmacPayload contains our HMAC
    // In a real implementation, this would be a proper HMAC verification
    const verified = hmacPayload.includes(config.hmac);
    
    return {
      verified,
      isMock: false,
      transactionId: 'transaction_id_from_payload',
      orderId: data.orderId || 'order_id_from_payload',
    };
  } catch (error) {
    console.error('Error verifying Paymob HMAC:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to verify payment. Please try again later.'
    );
  }
});

// 3. Seed Sample Data (HTTPS callable, admin only)
export const seedSampleData = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated and has admin privileges
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to seed data.'
    );
  }
  
  // Check if user is admin (in a real app, you'd check a custom claim or admin role)
  // For demo purposes, we'll allow any authenticated user to seed data
  
  try {
    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    
    // Create categories
    const categories = [
      { id: 'breads', name: 'Breads', imageUrl: 'https://source.unsplash.com/random/300x300/?bread', sortOrder: 1 },
      { id: 'pastries', name: 'Pastries', imageUrl: 'https://source.unsplash.com/random/300x300/?pastry', sortOrder: 2 },
      { id: 'cakes', name: 'Cakes', imageUrl: 'https://source.unsplash.com/random/300x300/?cake', sortOrder: 3 },
      { id: 'cookies', name: 'Cookies', imageUrl: 'https://source.unsplash.com/random/300x300/?cookie', sortOrder: 4 },
      { id: 'chocolates', name: 'Chocolates', imageUrl: 'https://source.unsplash.com/random/300x300/?chocolate', sortOrder: 5 },
    ];
    
    // Add categories to batch
    categories.forEach(category => {
      const categoryRef = db.collection('categories').doc(category.id);
      batch.set(categoryRef, {
        ...category,
        createdAt: timestamp,
        updatedAt: timestamp,
      });
    });
    
    // Create products (4 products per category)
    const products = [
      // Breads
      {
        id: 'sourdough-bread',
        name: 'Sourdough Bread',
        description: 'Artisanal sourdough bread with a crispy crust and soft interior.',
        ingredients: 'Flour, water, salt, sourdough starter.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?sourdough',
        priceEgp: 35.0,
        categoryId: 'breads',
        isFeatured: true,
        trendingScore: 8,
      },
      {
        id: 'baguette',
        name: 'French Baguette',
        description: 'Traditional French baguette with a crispy exterior and chewy interior.',
        ingredients: 'Flour, water, salt, yeast.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?baguette',
        priceEgp: 25.0,
        categoryId: 'breads',
        isFeatured: false,
        trendingScore: 6,
      },
      {
        id: 'multigrain-bread',
        name: 'Multigrain Bread',
        description: 'Healthy multigrain bread packed with seeds and grains.',
        ingredients: 'Whole wheat flour, oats, flax seeds, sunflower seeds, water, salt, yeast.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?multigrain',
        priceEgp: 40.0,
        categoryId: 'breads',
        isFeatured: false,
        trendingScore: 7,
      },
      {
        id: 'ciabatta',
        name: 'Ciabatta',
        description: 'Italian bread with a light, airy texture and crisp crust.',
        ingredients: 'Flour, water, salt, yeast, olive oil.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?ciabatta',
        priceEgp: 30.0,
        categoryId: 'breads',
        isFeatured: false,
        trendingScore: 5,
      },
      
      // Pastries
      {
        id: 'croissant',
        name: 'Butter Croissant',
        description: 'Flaky, buttery French pastry with a golden crust.',
        ingredients: 'Flour, butter, sugar, salt, yeast, milk.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?croissant',
        priceEgp: 15.0,
        categoryId: 'pastries',
        isFeatured: true,
        trendingScore: 9,
      },
      {
        id: 'pain-au-chocolat',
        name: 'Pain au Chocolat',
        description: 'Chocolate-filled croissant pastry with a buttery, flaky texture.',
        ingredients: 'Flour, butter, sugar, salt, yeast, milk, dark chocolate.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?pain-au-chocolat',
        priceEgp: 18.0,
        categoryId: 'pastries',
        isFeatured: false,
        trendingScore: 8,
      },
      {
        id: 'danish-pastry',
        name: 'Danish Pastry',
        description: 'Sweet pastry with fruit filling and vanilla custard.',
        ingredients: 'Flour, butter, sugar, eggs, milk, vanilla, fruit preserves.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?danish-pastry',
        priceEgp: 20.0,
        categoryId: 'pastries',
        isFeatured: false,
        trendingScore: 7,
      },
      {
        id: 'cinnamon-roll',
        name: 'Cinnamon Roll',
        description: 'Sweet roll with cinnamon-sugar filling and cream cheese frosting.',
        ingredients: 'Flour, butter, sugar, cinnamon, cream cheese, vanilla.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?cinnamon-roll',
        priceEgp: 22.0,
        categoryId: 'pastries',
        isFeatured: true,
        trendingScore: 9,
      },
      
      // Cakes
      {
        id: 'chocolate-cake',
        name: 'Chocolate Cake',
        description: 'Rich, moist chocolate cake with chocolate ganache frosting.',
        ingredients: 'Flour, sugar, cocoa powder, eggs, butter, vanilla, chocolate.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?chocolate-cake',
        priceEgp: 120.0,
        categoryId: 'cakes',
        isFeatured: true,
        trendingScore: 10,
      },
      {
        id: 'red-velvet',
        name: 'Red Velvet Cake',
        description: 'Classic red velvet cake with cream cheese frosting.',
        ingredients: 'Flour, sugar, cocoa powder, red food coloring, eggs, butter, cream cheese.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?red-velvet',
        priceEgp: 140.0,
        categoryId: 'cakes',
        isFeatured: false,
        trendingScore: 8,
      },
      {
        id: 'carrot-cake',
        name: 'Carrot Cake',
        description: 'Spiced carrot cake with walnuts and cream cheese frosting.',
        ingredients: 'Flour, sugar, carrots, walnuts, cinnamon, eggs, cream cheese.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?carrot-cake',
        priceEgp: 110.0,
        categoryId: 'cakes',
        isFeatured: false,
        trendingScore: 7,
      },
      {
        id: 'cheesecake',
        name: 'New York Cheesecake',
        description: 'Creamy New York style cheesecake with graham cracker crust.',
        ingredients: 'Cream cheese, sugar, eggs, vanilla, graham crackers, butter.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?cheesecake',
        priceEgp: 150.0,
        categoryId: 'cakes',
        isFeatured: true,
        trendingScore: 9,
      },
      
      // Cookies
      {
        id: 'chocolate-chip',
        name: 'Chocolate Chip Cookies',
        description: 'Classic chocolate chip cookies with a soft center and crisp edges.',
        ingredients: 'Flour, butter, sugar, brown sugar, eggs, vanilla, chocolate chips.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?chocolate-chip-cookie',
        priceEgp: 8.0,
        categoryId: 'cookies',
        isFeatured: true,
        trendingScore: 9,
      },
      {
        id: 'oatmeal-raisin',
        name: 'Oatmeal Raisin Cookies',
        description: 'Chewy oatmeal cookies with plump raisins and a hint of cinnamon.',
        ingredients: 'Flour, oats, butter, sugar, eggs, raisins, cinnamon.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?oatmeal-cookie',
        priceEgp: 8.0,
        categoryId: 'cookies',
        isFeatured: false,
        trendingScore: 6,
      },
      {
        id: 'peanut-butter',
        name: 'Peanut Butter Cookies',
        description: 'Soft peanut butter cookies with the classic crisscross pattern.',
        ingredients: 'Flour, peanut butter, butter, sugar, eggs, vanilla.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?peanut-butter-cookie',
        priceEgp: 9.0,
        categoryId: 'cookies',
        isFeatured: false,
        trendingScore: 7,
      },
      {
        id: 'shortbread',
        name: 'Shortbread Cookies',
        description: 'Buttery, crumbly Scottish shortbread cookies.',
        ingredients: 'Flour, butter, sugar.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?shortbread',
        priceEgp: 7.0,
        categoryId: 'cookies',
        isFeatured: false,
        trendingScore: 5,
      },
      
      // Chocolates
      {
        id: 'dark-chocolate-truffles',
        name: 'Dark Chocolate Truffles',
        description: 'Rich dark chocolate truffles dusted with cocoa powder.',
        ingredients: 'Dark chocolate, heavy cream, butter, cocoa powder.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?chocolate-truffle',
        priceEgp: 15.0,
        categoryId: 'chocolates',
        isFeatured: true,
        trendingScore: 8,
      },
      {
        id: 'chocolate-covered-strawberries',
        name: 'Chocolate Covered Strawberries',
        description: 'Fresh strawberries dipped in premium chocolate.',
        ingredients: 'Strawberries, dark chocolate, white chocolate.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?chocolate-strawberry',
        priceEgp: 25.0,
        categoryId: 'chocolates',
        isFeatured: true,
        trendingScore: 9,
      },
      {
        id: 'assorted-chocolates',
        name: 'Assorted Chocolate Box',
        description: 'Handcrafted selection of milk, dark, and white chocolates with various fillings.',
        ingredients: 'Milk chocolate, dark chocolate, white chocolate, nuts, caramel, fruit fillings.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?chocolate-box',
        priceEgp: 120.0,
        categoryId: 'chocolates',
        isFeatured: false,
        trendingScore: 7,
      },
      {
        id: 'chocolate-bark',
        name: 'Chocolate Bark with Nuts',
        description: 'Dark chocolate bark loaded with assorted nuts and dried fruits.',
        ingredients: 'Dark chocolate, almonds, pistachios, walnuts, dried cranberries.',
        imageUrl: 'https://source.unsplash.com/random/400x300/?chocolate-bark',
        priceEgp: 60.0,
        categoryId: 'chocolates',
        isFeatured: false,
        trendingScore: 6,
      },
    ];
    
    // Add products to batch
    products.forEach(product => {
      const productRef = db.collection('products').doc(product.id);
      batch.set(productRef, {
        ...product,
        createdAt: timestamp,
        updatedAt: timestamp,
      });
    });
    
    // Commit the batch
    await batch.commit();
    
    return {
      success: true,
      message: 'Sample data seeded successfully',
      categoriesCount: categories.length,
      productsCount: products.length,
    };
  } catch (error) {
    console.error('Error seeding sample data:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to seed sample data. Please try again later.'
    );
  }
});

// 4. On Order Created (Firestore trigger)
export const onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data() as any;
    const orderId = context.params.orderId;
    
    try {
      // Get user details for personalized notification
      const userDoc = await db.collection('users').doc(order.userId).get();
      const user = userDoc.data();
      
      // Prepare notification data
      const notificationData = {
        title: 'New Order Received',
        body: `Your order #${orderId.substring(0, 8)} has been received and is being processed.`,
        orderId,
        status: order.status,
      };
      
      // Send notification to 'orders' topic (for admin notifications)
      await admin.messaging().sendToTopic('orders', {
        notification: {
          title: 'New Order',
          body: `Order #${orderId.substring(0, 8)} has been placed.`,
        },
        data: {
          orderId,
          status: order.status,
          userId: order.userId,
          amount: order.total.toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      });
      
      // Send notification to user if they have a FCM token
      // In a real app, you would store FCM tokens in Firestore
      if (user && user.fcmToken) {
        await admin.messaging().send({
          token: user.fcmToken,
          notification: {
            title: notificationData.title,
            body: notificationData.body,
          },
          data: {
            orderId,
            status: order.status,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        });
      }
      
      // Update order with notification sent timestamp
      await snapshot.ref.update({
        notificationSent: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return { success: true };
    } catch (error) {
      console.error('Error sending order notification:', error);
      return { success: false, error: (error as any).message };
    }
  });

// 5. Progress Order Status (HTTPS callable)
export const progressOrderStatus = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to update order status.'
    );
  }
  
  const { orderId } = data;
  
  if (!orderId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Order ID is required.'
    );
  }
  
  try {
    // Get the order
    const orderRef = db.collection('orders').doc(orderId);
    const orderDoc = await orderRef.get();
    
    if (!orderDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Order not found.'
      );
    }
    
    const order = orderDoc.data() as any;
    
    // Check if user is authorized (either admin or order owner)
    // In a real app, you'd check admin role or custom claims
    if (order.userId !== context.auth.uid) {
      // For demo purposes, we'll allow any authenticated user to update status
      console.log('Warning: Non-owner updating order status (demo mode)');
    }
    
    // Progress the status
    let newStatus;
    let newStatusMessage;
    
    switch (order.status) {
      case 'processing':
        newStatus = 'baking';
        newStatusMessage = 'Your order is now being baked!';
        break;
      case 'baking':
        newStatus = 'out_for_delivery';
        newStatusMessage = 'Your order is out for delivery!';
        break;
      case 'out_for_delivery':
        newStatus = 'delivered';
        newStatusMessage = 'Your order has been delivered!';
        break;
      case 'delivered':
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Order is already delivered and cannot progress further.'
        );
      default:
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid order status.'
        );
    }
    
    // Update the order status
    await orderRef.update({
      status: newStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Send notification to user about status change
    // In a real app, you'd get the user's FCM token from Firestore
    if (order.userId) {
      const userDoc = await db.collection('users').doc(order.userId).get();
      const user = userDoc.data();
      
      if (user && user.fcmToken) {
        await admin.messaging().send({
          token: user.fcmToken,
          notification: {
            title: 'Order Status Updated',
            body: newStatusMessage,
          },
          data: {
            orderId,
            status: newStatus,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        });
      }
    }
    
    return {
      success: true,
      orderId,
      previousStatus: order.status,
      newStatus,
      message: newStatusMessage,
    };
  } catch (error) {
    console.error('Error updating order status:', error);
    throw new functions.https.HttpsError(
      'internal',
      (error as any).message || 'Failed to update order status.'
    );
  }
});

// Optional: Scheduled function to auto-progress orders (commented out for demo)
/*
export const autoProgressOrders = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    try {
      // Get orders that have been in their current status for more than 5 minutes
      const timestamp = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 5 * 60 * 1000)
      );
      
      // Query orders by status and updatedAt
      const processingOrders = await db.collection('orders')
        .where('status', '==', 'processing')
        .where('updatedAt', '<', timestamp)
        .limit(10)
        .get();
        
      const bakingOrders = await db.collection('orders')
        .where('status', '==', 'baking')
        .where('updatedAt', '<', timestamp)
        .limit(10)
        .get();
        
      const deliveryOrders = await db.collection('orders')
        .where('status', '==', 'out_for_delivery')
        .where('updatedAt', '<', timestamp)
        .limit(10)
        .get();
      
      const batch = db.batch();
      const now = admin.firestore.FieldValue.serverTimestamp();
      
      // Update processing orders to baking
      processingOrders.docs.forEach(doc => {
        batch.update(doc.ref, { 
          status: 'baking', 
          updatedAt: now 
        });
      });
      
      // Update baking orders to out_for_delivery
      bakingOrders.docs.forEach(doc => {
        batch.update(doc.ref, { 
          status: 'out_for_delivery', 
          updatedAt: now 
        });
      });
      
      // Update out_for_delivery orders to delivered
      deliveryOrders.docs.forEach(doc => {
        batch.update(doc.ref, { 
          status: 'delivered', 
          updatedAt: now 
        });
      });
      
      await batch.commit();
      
      return {
        success: true,
        processed: {
          processing: processingOrders.size,
          baking: bakingOrders.size,
          delivery: deliveryOrders.size,
        }
      };
    } catch (error) {
      console.error('Error auto-progressing orders:', error);
      return { success: false, error: error.message };
    }
  });
*/
